#!/usr/bin/env bash

nix shell .#node2nix --command node2nix --lock package-lock.json --supplement-input supplement.json --nodejs-14
