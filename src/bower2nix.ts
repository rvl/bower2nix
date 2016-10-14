/// <reference path="../typings/tsd.d.ts" />

'use strict';

import path = require('path');
import util = require('util');
import child_process = require('child_process');
import os = require('os');
import glob = require('glob');
import argparse = require('argparse');
import fs = require('fs');
import stream = require('stream');
import semver = require('semver');
import _ = require('lodash');
import fsx = require('fs-extra');
let temp = require('promised-temp').track();

let version = require('../package.json').version;

function parseArgs() {
  const bowerJson = "bower.json";

  let parser = new argparse.ArgumentParser({
    version: version,
    description: 'Generate nix expressions to fetch bower dependencies'
  });

  parser.addArgument([ 'bowerJson' ], {
    help: 'The bower.json file (default: ./bower.json)',
    type: 'string',
    metavar: 'INPUT',
    defaultValue: bowerJson,
    nargs: '?'
  });

  parser.addArgument([ 'output' ], {
    help: 'The output file to generate (default: stdout)',
    metavar: 'OUTPUT',
    defaultValue: '-',
    nargs: '?'
  });

  let args = parser.parseArgs();

  if (args.bowerJson === bowerJson) {
    try {
      fs.statSync(args.bowerJson);
    } catch (err) {
      if (err.code === 'ENOENT') {
        parser.printHelp();
        process.exit(1);
      } else {
        error(err);
      }
    }
  }

  args.bowerJson = path.resolve(args.bowerJson);

  return args;
}

function error(message: string) {
  console.error(message);
  process.exit(1);
}

interface Dependencies {
  [index: string]: string;
};

interface BowerInfo {
  version: string;
  dependencies: Dependencies;
  devDependencies: Dependencies;
  resolutions: Dependencies;
}

interface FetchResult {
  name: string;
  target: string;
  success: boolean;
}

interface FetchBower extends FetchResult {
  version: string;
  hash: string;
  moreDeps: Dependencies;
}

interface FetchRelative extends FetchResult {
  includeDeps: string;
}

interface FetchError extends FetchResult {
  msg: string;
}

type DepResult = FetchError | FetchBower | FetchRelative;

/**
 * User-defined type guard for DepResult.
 */
function fetchSuccess(dep: DepResult): dep is FetchBower {
  return dep.success;
}

function isFetchRelative(dep: any): dep is FetchRelative {
  return !!dep.includeDeps;
}

/**
 * Gets the version info for a dep.
 */
async function handleDep(key: string, value: string): Promise<DepResult> {
  let endpointParser = require('bower-endpoint-parser');
  let tmpdir: string;
  let info: BowerInfo;
  let hash: string;

  //console.log(`handleDep(${key}, ${value})`);

  if (isRelativePath(value)) {
    return {
      success: false,
      name: key,
      target: value,
      includeDeps: value
    };
  }

  try {
    tmpdir = await temp.mkdir({ dir: os.tmpdir(), prefix: "bower2nix" });
  } catch (err) {
    error(`Creating temporary directory failed: ${err}`);
  }

  try {
    info = await spawnFetchBower(tmpdir, key, value);
    hash = await nixHash(tmpdir);
  } catch (err) {
    return {
      success: false,
      name: key,
      target: value,
      msg: err
    };
  } finally {
    fsx.remove(tmpdir, () => {});
  }

  let endpoint: any = _.assign(endpointParser.decompose(value), { name: key });
  let rangeValue = value;
  let versionWithSource = info.version;

  if (containsSource(value) || isGitRepo(value)) {
    // "value" can contain a source specification as well. For this case keep the
    // source also for the resolved version, so that fetch-bower can still find
    // it.
    rangeValue = endpoint.target;
    versionWithSource = endpoint.source + "#" + info.version;
  }

  let version = (semver.validRange(rangeValue, true) && info.version) ? versionWithSource : value;

  return {
    success: true,
    name: key,
    version: version,
    target: value,
    hash: hash,
    moreDeps: info.dependencies
  };
}

function isRelativePath(value: string): boolean {
  return !!value.match(/^\.\.?\//);
}

function containsSource(value: string) {
  return value && value.indexOf("#") >= 0;
}

function isGitRepo(value: string) {
  return value &&
    (value.indexOf("git://") === 0 ||
     (value.match(/\//g) || []).length === 1);
}

function spawnFetchBower2(path: string, name: string, version: string): Promise<BowerInfo> {
  return fetchBower(path, name, version, version);
}

/**
 * Spawn a new process to fetch the bower config for a module.
 */
function spawnFetchBower(path: string, name: string, version: string): Promise<BowerInfo> {
  let proc = child_process.spawn(__dirname + "/../bin/fetch-bower", [
    "--out", path,
    name,
    version
  ], { stdio: [ 0, 'pipe', 2 ] });

  return new Promise((resolve, reject) => {
    let info: BowerInfo;
    let bufs: Buffer[] = [];
    let bufSize = 0;
    let readInfo = () => {
      let buf = proc.stdout.read();
      if (buf) {
        bufs.push(buf);
        bufSize += buf.length;
      }
    };
    proc.stdout.on('readable', readInfo);
    proc.stdout.on('end', () => {
      info = JSON.parse(Buffer.concat(bufs, bufSize).toString());
      resolve(info);
    });
    proc.once('error', (err: {}) => {
      reject(`fetch-bower failed to exec with error ${util.inspect(err)}`);
    });
    proc.once('exit', (code: number, signal: number) => {
      if (signal) {
        reject(`fetch-bower exited due to signal ${signal}`);
      } else if (code !== 0) {
        reject(`fetch-bower exited with non-zero exit code ${code}`);
      } else if (!info) {
        reject("fetch-bower exited before outputting the info");
      } else {
        resolve(info);
      }
    });
  });
}

/**
 * Runs nix-hash on a file and collects the resulting base32 encoded
 * hash.
 */
function nixHash(path: string): Promise<string> {
  //console.log(`nix-hash --base32 --type sha256 ${path}`);
  let proc = child_process.spawn("nix-hash", [
    "--base32",
    "--type", "sha256",
    path
  ], { stdio: [ 0, 'pipe', 2 ] });

  return new Promise((resolve, reject) => {
    let buf: string;
    let readHash = () => {
      buf = proc.stdout.read(52);
      if (buf) {
        proc.stdout.removeListener('readable', readHash);
        //console.log("got a hash: " + buf);
        resolve(buf.toString());
      }
    };
    proc.stdout.on('readable', readHash);
    proc.once('exit', (code: number, signal: number) => {
      if (!code) {
        reject(`nix-hash exited with signal ${signal}`);
      } else if (code !== 0) {
        reject(`nix-hash exited with non-zero exit code ${code}`);
      } else if (!buf) {
        reject("nix-hash exited before outputting the hash");
      } else {
        resolve(buf.toString);
      }
    });
    proc.once('error', (err: {}) => {
      reject(`nix-hash failed to exec with error ${err}`);
    });
  });
}

function readBower(filename: string): Promise<BowerInfo> {
  let bowerJson = require('bower-json');

  return new Promise((resolve, reject) => {
    let handler = (err: string, json: BowerInfo) => {
      if (err) {
        reject(err);
      } else {
        resolve(json);
      }
    };
    return bowerJson.read(filename, { normalize: true }, handler);
  });
}

async function parseBowerJsonDeps(filename: string): Promise<Dependencies> {
  let json = await readBower(filename);
  return _.merge(<any>{}, json.dependencies,
                 json.devDependencies, json.resolutions);
}

async function parseBowerJson(filename: string): Promise<DepResult[]> {
  let result: DepResult[] = [];
  var deps: Dependencies;
  try {
    deps = await parseBowerJsonDeps(filename);
  } catch (err) {
    error(`Parsing ${filename} failed: ${err}`);
  }
  let queue = _.keys(deps);

  while (queue.length > 0) {
    let name = queue.shift();
    let version = deps[name];
    let dep = await handleDep(name, version);

    if (fetchSuccess(dep)) {
      _.each(dep.moreDeps, (version: string, name: string) => {
        if (!deps[name]) {
          deps[name] = version;
          queue.push(name);
        }
      });
      result.push(dep);
    } else if (isFetchRelative(dep)) {
      // include deps from a nearby bower.json
      try {
        let more = await parseBowerJsonDeps(relativeBowerJson(filename, dep.includeDeps));
        _(more).keys().each(key => queue.push(key));
        deps = <Dependencies>_.assign({}, more, deps);
        result.push({
          success: true,
          name: dep.name,
          target: dep.target,
          version: dep.target,
          hash: "0000000000000000000000000000000000000000000000000000",
          moreDeps: {}
        });
      } catch (err) {
        // the error will be reported in output file
      }
    } else {
      result.push(dep);
    }
  }

  return result;
}

function relativeBowerJson(original: string, relative: string):string  {
  return path.join(path.dirname(original), relative, "bower.json");
}

function writeHeader(output: NodeJS.WritableStream) {
  // please note: program output is all yours, NOT copyrighted or covered by GPL
  output.write(`# Generated by bower2nix v${version} (https://github.com/rvl/bower2nix)\n`);
  output.write("{ fetchbower, buildEnv }:\n");
  output.write("buildEnv { name = \"bower-env\"; ignoreCollisions = true; paths = [\n");
}

function writeLine(output: NodeJS.WritableStream, dep: FetchBower) {
  output.write(`  (fetchbower \"${dep.name}\" \"${dep.version}\" \"${dep.target}\" \"${dep.hash}\")\n`);
}

function writeErrorLine(output: NodeJS.WritableStream, err: FetchError) {
  output.write(`  # failed to fetch \"${err.name}\": ${err.msg}\n`);
}

function writeRelativeErrorLine(output: NodeJS.WritableStream, err: FetchRelative) {
  output.write(`  # failed to load relative dep \"${err.includeDeps}\"\n`);
}

function writeFooter(output: NodeJS.WritableStream) {
  output.write("]; }\n");
}

export async function bower2nixMain() {
  let args = parseArgs();

  let output = args.output === '-' ? process.stdout
    : fs.createWriteStream(path.resolve(args.output));

  writeHeader(output);

  for (let dep of await parseBowerJson(args.bowerJson)) {
    if (fetchSuccess(dep)) {
      writeLine(output, dep);
    } else if (isFetchRelative(dep)) {
      writeRelativeErrorLine(output, dep);
    } else {
      writeErrorLine(output, dep);
    }
  }

  writeFooter(output);

  if (args.output !== '-') {
    await endFsStream(<fs.WriteStream>output);
  }
}

/**
 * Promise which resolves which the stream has been finished.
 */
function endFsStream(output: fs.WriteStream) {
  return new Promise(resolve => output.end(resolve));
}

/**
 * Promise version of glob().
 */
function globP(path: string): Promise<string[]> {
  return new Promise((resolve, reject) => {
    return glob(path, { nosort: true }, (err, files) => {
      if (err) {
        reject(err);
      } else {
        resolve(files);
      }
    });
  });
}

/**
 * Downloads a bower package and returns its info attributes.
 *
 * @outDir: output directory for package. Bower will create it.
 * @name: source package name.
 * @target: a npm version spec range (default: latest version)
 * @version: optionally, an exact version to get (default: according to version range)
 */
async function fetchBower(outDir: string, name: string, target?: string, version?: string): Promise<BowerInfo> {
  let bower = require('bower');
  let endpointParser = require('bower-endpoint-parser');
  let Logger = require('bower-logger');
  let PackageRepository = require('bower/lib/core/PackageRepository');

  bower.config.storage = bower.config.storage || {};
  bower.config.storage.packages = outDir + "/packages";
  bower.config.storage.registry = outDir + "/registry";
  bower.config.verbose = true;

  let repo = new PackageRepository(bower.config, new Logger());

  function patchTarget(info: any) {
    if (target) {
      info._target = target;
    }
    return info;
  }

  return <any>new Promise((resolve, reject) => {
    let endpoint = endpointParser.json2decomposed(name, version || target);
    repo.fetch(endpoint)
      .spread(async (path: string, info: BowerInfo) => {
        patchTarget(info);
        let reg = _.map(await globP(outDir + "/registry/*/lookup/*"), mutateFile((json: any) => {
          json["expires"] = 0;
          return json;
        }));
        let pkg = _.map(await globP(outDir + "/packages/*/*/.bower.json"), mutateFile((json: any) => {
          return patchTarget(json);
        }));
        Promise.all(_.concat(reg, pkg)).then(() => resolve(info), reject);
      });
  });
}

interface Mutator<T> {
  (filename: string): Promise<T>;
}

/**
 * Returns a function which reads a json file, runs a transformation
 * on the data, then writes the result back to the file.
 */
function mutateFile<T>(func: (ob: {}) => T): Mutator<T> {
  return (file: string) => {
    return new Promise((resolve, reject) => {
      fs.readFile(file, (err, data) => {
        if (err) {
          reject(err);
        } else {
          let json = JSON.parse(data.toString());
          let json2 = func(json);
          fs.writeFile(file, JSON.stringify(json2), (err, data) => {
            if (err) {
              reject(err);
            } else {
              resolve(json2);
            }
          });
        }
      });
    });
  };
}

function parseFetchBowerArgs() {
  let parser = new argparse.ArgumentParser({
    version: version,
    description: 'Fetch a single bower dependency'
  });

  parser.addArgument([ '--out', '-o' ], {
    help: 'Output directory',
    type: path.resolve,
    metavar: 'DIR'
  });

  parser.addArgument([ '--quiet', '-q' ], {
    help: "Don't print package json",
    action: "storeTrue"
  });

  parser.addArgument([ 'name' ], {
    help: 'Package name',
    type: 'string',
    metavar: 'NAME'
  });

  parser.addArgument([ 'target' ], {
    help: 'Target version range',
    type: 'string',
    metavar: 'TARGET',
    defaultValue: null,
    nargs: '?'
  });

  parser.addArgument([ 'version' ], {
    help: 'Exact package version',
    type: 'string',
    metavar: 'VERSION',
    defaultValue: null,
    nargs: '?'
  });

  return parser.parseArgs();
}

export async function fetchBowerMain() {
  let args = parseFetchBowerArgs();
  let tmpdir = await temp.mkdir({ dir: os.tmpdir(), prefix: "fetch-bower" });
  let out = args.out || tmpdir;

  // bower needs a writable "home directory"
  process.env.HOME = tmpdir;

  let info = await fetchBower(out, args.name, args.target, args.version);
  if (!args.quiet) {
    process.stdout.write(JSON.stringify(info));
  }
}
