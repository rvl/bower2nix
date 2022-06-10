#!/usr/bin/env nix-shell
#! nix-shell -i bash -p nodePackages.node2nix

node2nix --lock package-lock.json --supplement-input supplement.json --nodejs-14
