{ bower2nix ? { outPath = ./.; name = "bower2nix"; }
, pkgs ? import <nixpkgs> {}
}:
let
  nodePackages = import "${pkgs.path}/pkgs/top-level/node-packages.nix" {
    inherit pkgs;
    inherit (pkgs) stdenv nodejs fetchurl fetchgit;
    neededNatives = [ pkgs.python ] ++ pkgs.lib.optional pkgs.stdenv.isLinux pkgs.utillinux;
    self = nodePackages;
    generated = ./node-packages.nix;
  };
in rec {
  tarball = pkgs.runCommand "bower2nix-2.1.0.tgz" { buildInputs = [ pkgs.nodejs ]; } ''
    mv `HOME=$PWD npm pack ${bower2nix}` $out
  '';
  build = nodePackages.buildNodePackage {
    name = "bower2nix-2.1.0";
    src = [ tarball ];
    buildInputs = nodePackages.nativeDeps."bower2nix" or [];
    deps = [ nodePackages.by-spec."temp"."0.6.0" nodePackages.by-spec."fs.extra".">=1.2.1 <2" nodePackages.by-spec."bower-json"."0.4.0" nodePackages.by-spec."bower-endpoint-parser"."0.2.1" nodePackages.by-spec."bower-logger"."0.2.1" nodePackages.by-spec."bower".">=1.2.8 <2" nodePackages.by-spec."argparse"."0.1.15" nodePackages.by-spec."clone"."0.1.11" nodePackages.by-spec."semver".">=2.2.1 <3" nodePackages.by-spec."fetch-bower".">=2 <3" ];
    peerDependencies = [];
  };
}