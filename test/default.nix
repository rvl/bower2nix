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

  bower2nix = import ./.. { inherit pkgs; };

  # fetch-bower-3.0.0 has different command line args from fetch-bower-2.0.0
  # nixpkgs will need a pull request for this change.
  # Also the quoting of fetch-bower arguments was fixed
  fetchbower = name: version: target: outputHash: pkgs.stdenv.mkDerivation {
    name = "${name}-${bowerVersion version}";
    buildCommand = "fetch-bower --quiet --out=$out '${name}' '${target}' '${version}'";
    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    inherit outputHash;
    buildInputs = [ bower2nix ];
  };

  bowerVersion = version:
    let
      components = pkgs.lib.splitString "#" version;
      hash = pkgs.lib.last components;
      ver = if builtins.length components == 1 then version else hash;
    in ver;


  # running bower2nix from nix can't really work properly.
  bowerGeneratedNix = pkgs.stdenv.mkDerivation {
    name = "bower-generated.nix";
    src = test;
    buildInputs = [ bower2nix ];
    buildPhase = "bower2nix bower.json $out";
    installPhase = "true";
    preferLocalBuild = true;
  };

in bowerComponents
