{ test ? { outPath = ./.; name = "bower2nix-test"; }
, pkgs ? import <nixpkgs> {}
}:

let
  # To regenerate, run:
  #   bower2nix bower.json bower-generated.nix
  bowerPackages = import ./bower-generated.nix {
    inherit (pkgs) buildEnv;

    # # Usually you get fetchbower from <nixpkgs> but for this example,
    # # we will override the fetch-bower command used.
    # fetchbower = pkgs.fetchbower.override {
    #   inherit fetch-bower;
    # };
    inherit fetchbower;
  };

  bowerComponents = pkgs.stdenv.mkDerivation {
    name = "bower_components";
    inherit bowerPackages;
    src = test;
    buildPhase = ''
      cp -RL --reflink=auto ${bowerPackages} bc
      chmod -R u+w bc
      HOME=$PWD bower \
          --config.storage.packages=bc/packages \
          --config.storage.registry=bc/registry \
          --offline install
    '';
    installPhase = "mv bower_components $out";
    buildInputs = [
      pkgs.git
      bowerPackages
      pkgs.nodePackages.bower
    ];
  };

  fetch-bower = import ./.. { inherit pkgs; };

  # fetch-bower-3.0.0 has different command line args from fetch-bower-2.0.0
  # nixpkgs will need a pull request for this change.
  # Also the quoting of fetch-bower arguments was fixed
  fetchbower = name: version: target: outputHash: pkgs.stdenv.mkDerivation {
    name = "${name}-${version}";
    buildCommand = "fetch-bower --out=$out '${name}' '${target}' '${version}'";
    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    inherit outputHash;
    buildInputs = [pkgs.git fetch-bower];
  };

in bowerComponents
