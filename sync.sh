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
git merge --no-edit -X theirs origin/main

# Get the latest flake.lock from the same upstream branch
nix flake update --accept-flake-config --override-flake nixpkgs "github:NixOS/nixpkgs/$branch"

# Commit the changes
if [[ -n $(git status --porcelain) ]]; then
  git commit -am "flake update nixpkgs/$branch"
fi

# # Warm up the binary cache
# ./ci.sh || true

# Push if there are new changes
git push origin "HEAD:$branch"
