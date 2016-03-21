{ bower2nix ? { outPath = ./.; name = "bower2nix"; }
, pkgs ? import <nixpkgs> {}
}:
let
  version = "3.0.1";
  nodePackages = import "${pkgs.path}/pkgs/top-level/node-packages.nix" {
    inherit pkgs;
    inherit (pkgs) stdenv nodejs fetchurl fetchgit;
    neededNatives = [ pkgs.python ] ++ pkgs.lib.optional pkgs.stdenv.isLinux pkgs.utillinux;
    self = nodePackages;
    generated = ./node-packages.nix;
  };
  getDrvs = with pkgs.stdenv.lib; pkgs: (filter (v: nixType v == "derivation") (attrValues pkgs));
  tarball = pkgs.runCommand "bower2nix-${version}.tgz" { buildInputs = [ pkgs.nodejs ]; } ''
    mv `HOME=$PWD npm pack ${bower2nix} --ignore-scripts` $out
  '';
in

nodePackages.buildNodePackage rec {
  name = "bower2nix-${version}";
  src = [ tarball ];
  buildInputs = nodePackages.nativeDeps."bower2nix" or [
    nodePackages.typescript
  ];
  peerDependencies = [];
  deps = allDeps;
  allDeps = getDrvs nodePackages;
  postBuild = "tsc";
  postInstall = "mv dist $out/lib/node_modules/bower2nix/dist";
  propagatedBuildInputs = [ pkgs.git ];
}
