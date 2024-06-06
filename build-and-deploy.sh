#!/bin/env bash

set -xe

result=`nix-build`
nix-copy-closure --to pi2 $result
ssh -t paul@pi2 sudo $result/nixos-rebuild-switch
