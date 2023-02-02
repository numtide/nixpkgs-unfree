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
# git fetch origin "refs/heads/$branch:refs/heads/$branch" || true

# Checkout that branch in a temporary worktree
git worktree add -f -b "$branch" "$workdir"

# Start working
cd "$workdir"

# Get the latest flake.lock from the same upstream branch
nix flake update --override-flake nixpkgs "github:NixOS/nixpkgs/$branch"

# Commit the changes
git commit -am "$branch sync"

# # Warm up the binary cache
# ./ci.sh || true

# Erase previous results
# TODO: make the commits incremental instead
# TODO: only push if there are some changes
git push -f origin "HEAD:$branch"
