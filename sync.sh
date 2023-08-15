#!/usr/bin/env bash
# A little script that helps keep upstream and this repo in sync
set -exuo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
branch=${1:-nixos-unstable}

workdir=$(mktemp -d)
cleanup() {
  cd "$here"
  git worktree remove --force "$workdir"
  rm -rf "$workdir"
}
trap cleanup EXIT

# Get the latest commit from that branch
git fetch origin "refs/heads/main"
git fetch origin "refs/heads/$branch" || true

# Checkout that branch in a temporary worktree
git worktree add -f "$workdir" "$branch"

# Start working
cd "$workdir"

# Get the latest code from the main branch
git merge -X theirs origin/main

# Get the latest flake.lock from the same upstream branch
nix flake update --accept-flake-config --override-flake nixpkgs "github:NixOS/nixpkgs/$branch"

# Commit the changes
git commit -am "$branch sync"

# # Warm up the binary cache
# ./ci.sh || true
bash

# Erase previous results
# TODO: only push if there are some changes
git push origin "HEAD:$branch"
