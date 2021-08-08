{
  inputs = {

    nixpkgs.url = "nixpkgs/nixos-unstable";

    nixpkgsOld.url = "nixpkgs/18.03";
    nixpkgsOld.flake = false;
  };

  outputs = inp: let
    supportedSystems = [ "x86_64-linux" ];
    lib = inp.nixpkgs.lib;
  in
    lib.foldl' lib.recursiveUpdate {} (lib.forEach supportedSystems (system: 
      let 
        pkgsOld = import inp.nixpkgsOld { inherit system; };
      in
      {
        packages."${system}".bower2nix = pkgsOld.nodePackages.bower2nix;
      }));
}
