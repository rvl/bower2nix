#!/usr/bin/env bash

$(nix-build node2nix.nix)/bin/node2nix --lock package-lock.json --supplement-input supplement.json --nodejs-14
