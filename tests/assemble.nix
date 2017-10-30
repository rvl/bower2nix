{ pkgs ? import <nixpkgs> {}, name, generated ? null }:

let
  src = pkgs.lib.cleanSource ./.;
  generated' = if generated == null then "${name}.nix" else generated;

in pkgs.buildBowerComponents {
  name = "bower2nix-test-${name}";
  generated = "${src}/${generated'}";
  src = pkgs.runCommand "${name}-bower.json" {} ''
    mkdir -p $out
    cp ${src}/${name}.json $out/bower.json
  '';
}
