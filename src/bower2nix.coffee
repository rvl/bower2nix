path = require 'path'
util = require 'util'
child_process = require 'child_process'
os = require 'os'

argparse = require 'argparse'
temp = require 'temp'
fs = require 'fs.extra'
clone = require 'clone'
semver = require 'semver'

bowerJson = require 'bower-json'
endpointParser = require 'bower-endpoint-parser'
Logger = require 'bower-logger'
PackageRepository = require 'bower/lib/core/PackageRepository'
bower = require 'bower'

version = require('../package.json').version

parser = new argparse.ArgumentParser {
  version: version
  description: 'Generate nix expressions to fetch bower dependencies'
}

parser.addArgument [ 'bowerJson' ],
  help: 'The bower.json file'
  type: path.resolve
  metavar: 'INPUT'

parser.addArgument [ 'output' ],
  help: 'The output file to generate'
  type: path.resolve
  metavar: 'OUTPUT'

args = parser.parseArgs()

temp.track()

output = fs.createWriteStream args.output
output.write "{ fetchBower }:\n"
output.write "[\n"

logger = new Logger()

error = (mesage) ->
  console.error message
  process.exit 1

bowerJson.read args.bowerJson, normalize: true, (err, json) ->
  error "Parsing #{args.bowerJson} failed: #{err}" if err?
  for key, value of json.dependencies
    do (key, value) ->
      temp.mkdir { dir: os.tmpDir(), prefix: "bower2nix" }, (err, tmpdir) ->
        error "Creating temporary directory failed: #{err}" if err?
        config = clone bower.config
        config.storage ?= {}
        config.storage.packages = "#{tmpdir}/packages"
        config.storage.registry = "#{tmpdir}/registry"
        new PackageRepository(config, logger).fetch(endpointParser.json2decomposed key, value)
          .spread (path, info) ->
            nixHash = child_process.spawn "nix-hash", [
              "--base32"
              "--type", "sha256"
              tmpdir
            ], stdio: [ 0, 'pipe', 2 ]
            earlyClose = ->
              error "nix-hash stdout closed with data still to read"
            nixHash.on 'close', earlyClose
            readHash = ->
              buf = nixHash.stdout.read 52
              if buf?
                nixHash.stdout.removeListener 'readable', readHash
                nixHash.removeListener 'close', earlyClose
                if semver.validRange value, true and info.version?
                  value = info.version
                output.write "  (fetchBower \"#{key}\" \"#{value}\" \"#{buf.toString()}\")\n"
                fs.rmrf tmpdir, ->
            nixHash.stdout.on 'readable', readHash
            nixHash.on 'exit', (code, signal) ->
              unless code?
                error "nix-hash exited with signal #{signal}"
              else unless code is 0
                error "nix-hash exited with non-zero exit code #{code}"
            nixHash.on 'error', (err) ->
              error "nix-hash failed to exec with error #{util.inspect err}"

process.on "exit", (code) ->
  if code is 0
    output.write "]\n"
    output.close()
