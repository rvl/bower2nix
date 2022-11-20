{ pkgs ?
  let
    hash = "f42a45c015f28ac3beeb0df360e50cdbf495d44b";
    url = "https://github.com/NixOS/nixpkgs/archive/${hash}.tar.gz";
  in
    import (fetchTarball url) {}
}:
let
  bower2nix = (pkgs.callPackage ./. {}).package.overrideAttrs (attrs: {
    installPhase = ''
      ${attrs.installPhase}
      npm run prepare
      cp -r dist $out
    '';
  });
in
  bower2nix
