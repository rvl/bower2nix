{
  description = "bower2nix: Generate nix expressions to fetch bower dependencies";

  inputs.node2nix.url = "github:svanderburg/node2nix/a6041f67b8d4a300c6f8d097289fe5addbc5edf8";
  inputs.node2nix.flake = false;

  outputs = { self, nixpkgs, node2nix }: let
    supportedSystems = nixpkgs.lib.systems.flakeExposed;
    forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: (forSystem system f));
    forSystem = system: f: f rec {
      inherit system;
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          self.overlays.bower2nix
          self.overlays.node2nix
        ];
      };
      lib = pkgs.lib;
    };
  in {
    overlays.default = self.overlays.bower2nix;
    overlays.bower2nix = final: prev: let
      build = final.callPackage ./. {};
    in {
      bower2nix = build.package.overrideAttrs (attrs: {
        installPhase = ''
          ${attrs.installPhase}
          npm run prepare
          cp -r dist $out
        '';
        passthru = attrs.passthru or {} // build;
      });
    };
    overlays.node2nix = final: prev: {
      node2nix = (final.callPackage node2nix {}).package;
    };

    packages = forAllSystems ({ pkgs, system, ... }: {
      inherit (pkgs) bower2nix node2nix;
      default = self.packages.${system}.bower2nix;
    });
    devShells = forAllSystems ({ pkgs, system, ... }: {
      bower2nix = pkgs.bower2nix.shell;
      default = self.devShells.${system}.bower2nix;
    });
  };
}
