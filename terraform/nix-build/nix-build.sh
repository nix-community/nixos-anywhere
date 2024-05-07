#!/usr/bin/env bash
set -efu

declare file attribute nix_options
eval "$(jq -r '@sh "attribute=\(.attribute) file=\(.file) nix_options=\(.nix_options)"')"
if [[ -n ${file-} ]] && [[ -e ${file-} ]]; then
  out=$(nix build --no-link --json $(echo "$nix_options") -f "$file" "$attribute")
  printf '%s' "$out" | jq -c '.[].outputs'
else
  out=$(nix build --no-link --json $(echo "$nix_options") "$attribute")
  printf '%s' "$out" | jq -c '.[].outputs'
fi
