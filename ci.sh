#!/usr/bin/env bash
set -euo pipefail
args=(
  "$@"
  --accept-flake-config
  --gc-roots-dir gc-root
  --max-memory-size "12000"
  --option allow-import-from-derivation false
  --show-trace
  --workers 4
  ./ci.nix
)

export NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1
error=0

for job in $(nix run github:nix-community/nix-eval-jobs -- "${args[@]}" | jq -r '. | @base64'); do
  echo "=========================="
  job=$(echo "$job" | base64 -d)
  error=$(echo "$job" | jq -r .error)
  if [[ -z $error ]]; then
    echo "ERROR: $error"
    error=1
  else
    echo "$job"
    drvPath=$(echo "$job" | jq -r .drvPath)
    set +e
    nix-store --realize "$drvPath"
    set -e
    if ! nix-store --realize "$drvPath"; then
      error=1
    fi
  fi
done

# TODO: improve the reporting
# exit "$error"
