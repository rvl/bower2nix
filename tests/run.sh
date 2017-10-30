#!/usr/bin/env bash

export NIX_PATH="nixpkgs=https://nixos.org/channels/${CHANNEL-nixos-unstable}/nixexprs.tar.xz"

cd $(dirname $0)

nix-shell ../default.nix -A shell --run "cd .. && tsc"

bower2nix=$(nix-build --no-out-link ../default.nix -A package)

PATH=$bower2nix/bin:$PATH

for tst in *.json; do
    echo "Testing bower2nix ${tst}"
    bower2nix ${tst} ${tst%.*}.nix
done

for tst in *.json; do
    name=${tst%.*}
    nix-build --out-link $name --argstr name $name assemble.nix
done
