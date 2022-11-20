with import <nixpkgs> {};

let
  commit = "a6041f67b8d4a300c6f8d097289fe5addbc5edf8";
  node2nixSrc = fetchTarball "https://github.com/svanderburg/node2nix/archive/${commit}.tar.gz";
in
  (callPackage node2nixSrc {}).package
