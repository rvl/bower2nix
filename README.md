# bower2nix

[![Build Status](https://travis-ci.org/rvl/bower2nix.svg?branch=master)](https://travis-ci.org/rvl/bower2nix)

Generate nix expressions to fetch bower dependencies.

## Usage

```
usage: bower2nix [-h] [-v] [INPUT] [OUTPUT]

Generate nix expressions to fetch bower dependencies

Positional arguments:
  INPUT          The bower.json file (default: ./bower.json)
  OUTPUT         The output file to generate (default: stdout)

Optional arguments:
  -h, --help     Show this help message and exit.
  -v, --version  Show program's version number and exit.
```

## Installing

The easiest way to install `bower2nix` is not to install it at
all. Just start a `nix-shell`:

    nix-shell -p nodePackages.bower2nix

## Example

If you have a `bower.json` file like this:

```json
{
  "name": "bower-test",
  "dependencies": {
    "angular": "~1.4.0"
  }
}
```

Then running `bower2nix bower.json bower-generated.nix` will generate
something like this:

```nix
# bower-generated.nix
{ fetchbower, buildEnv }:
buildEnv { name = "bower-env"; ignoreCollisions = true; paths = [
  (fetchbower "angular" "1.4.9" "~1.4.0" "0a2754zsxv9dngpg08gkr9fdwv75y986av12q4drf1sm8p8cj6bs")
]; }
```

The resulting derivation is a union of all the downloaded bower
packages (and their dependencies).

## How to use in your project

Usually, you want a `bower_components` directory. This can be
generated with `bower install` by pointing it at the environment of
downloaded bower packages.

```nix
  bowerComponents = pkgs.buildBowerComponents {
    name = "bower-test";
    generated = ./bower-generated.nix;
    src = mySources;
  };
```

The resulting derivation contains a `bower_components` directory which
is ready to use in your project's build process.

There is a small example within the `example` subdirectory of this repo.

For more information, see the [Nixpkgs manual][1].

[1]: http://nixos.org/nixpkgs/manual/#sec-bower

## Fetch Bower

For testing purposes, a single package can be downloaded. For example:
`fetch-bower angular '~1.4.0' '1.4.8'`. If no output directory is
provided, the package attributes will be shown, and the package
contents discarded.

```
usage: fetch-bower [-h] [-v] [--out DIR] NAME [TARGET] [VERSION]

Fetch a single bower dependency

Positional arguments:
  NAME               Package name
  TARGET             Target version range
  VERSION            Exact package version

Optional arguments:
  -h, --help         Show this help message and exit.
  -v, --version      Show program's version number and exit.
  --out DIR, -o DIR  Output directory
```

## Requirements

`bower2nix` requires Node.js 4.x or higher. The latest version of
`bower2nix` is in the 16.09 release of nixpkgs/NixOS, so use that.

## Authors

* Shea Levy  @shlevy
* Rodney Lorrimar  @rvl
