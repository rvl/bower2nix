#!/usr/bin/env bash

cd $(dirname $0)

for tst in *.json; do
    echo "Testing bower2nix ${tst}"
    bower2nix ${tst} ${tst%.*}.nix
done

for tst in *.json; do
    name=${tst%.*}
    nix-build -I "nixpkgs=https://nixos.org/channels/${CHANNEL-nixos-unstable}/nixexprs.tar.xz" --out-link $name --argstr name $name assemble.nix
done
