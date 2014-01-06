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
output.write "{ fetchbower, buildEnv }:\n"
output.write "buildEnv { name = \"bower-env\"; ignoreCollisions = true; paths = [\n"

logger = new Logger()

error = (message) ->
  console.error message
  process.exit 1

bowerJson.read args.bowerJson, normalize: true, (err, json) ->
  error "Parsing #{args.bowerJson} failed: #{err}" if err?
  for key, value of json.dependencies
    do (key, value) ->
      temp.mkdir { dir: os.tmpDir(), prefix: "bower2nix" }, (err, tmpdir) ->
        error "Creating temporary directory failed: #{err}" if err?
        env = clone process.env
        env.out = tmpdir
        fetch = child_process.spawn process.argv[0], [
          require.resolve 'fetch-bower/lib/command.js'
          key
          value
          value
        ], env: env, stdio: [ 0, 'pipe', 2 ]
        info = null
        do ->
          bufs = []
          bufSize = 0
          readInfo = ->
            buf = fetch.stdout.read()
            if buf?
              bufs.push buf
              bufSize += buf.length
          fetch.stdout.on 'readable', readInfo
          fetch.stdout.on 'end', ->
            info = JSON.parse Buffer.concat(bufs, bufSize).toString()
        fetch.once 'error', (err) ->
          error "fetch-bower failed to exec with error #{util.inspect err}"
        fetch.once 'exit', (code, signal) ->
          unless code?
            error "fetch-bower exited due to signal #{signal}"
          else unless code is 0
            error "fetch-bower exited with non-zero exit code #{code}"
          else unless info?
            error "fetch-bower exited before outputting the info"
          else
            nixHash = child_process.spawn "nix-hash", [
              "--base32"
              "--type", "sha256"
              tmpdir
            ], stdio: [ 0, 'pipe', 2 ]
            buf = null
            readHash = ->
              buf = nixHash.stdout.read 52
              if buf?
                nixHash.stdout.removeListener 'readable', readHash
                version = if semver.validRange(value, true) and info.version?
                  info.version
                else
                  value
                output.write "  (fetchbower \"#{key}\" \"#{version}\" \"#{value}\" \"#{buf.toString()}\")\n"
                fs.rmrf tmpdir, ->
            nixHash.stdout.on 'readable', readHash
            nixHash.once 'exit', (code, signal) ->
              unless code?
                error "nix-hash exited with signal #{signal}"
              else unless code is 0
                error "nix-hash exited with non-zero exit code #{code}"
              else unless buf?
                error "nix-hash exited before outputting the hash"
            nixHash.once 'error', (err) ->
              error "nix-hash failed to exec with error #{util.inspect err}"

process.on "exit", (code) ->
  if code is 0
    output.write "]; }\n"
    output.close()
