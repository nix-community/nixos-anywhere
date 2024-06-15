#!/usr/bin/env bash
set -efu

declare file attribute nix_options
eval "$(jq -r '@sh "attribute=\(.attribute) file=\(.file) nix_options=\(.nix_options)"')"
options=$(echo "${nix_options}" | jq -r '.options | to_entries | map("--option \(.key) \(.value)") | join(" ")')
if [[ -n ${file-} ]] && [[ -e ${fileh-} ]]; then
  # shellcheck disable=SC2086
  out=$(nix build --no-link --json $options -f "$file" "$attribute")
  printf '%s' "$out" | jq -c '.[].outputs'
else
  # shellcheck disable=SC2086
  out=$(nix build --no-link --json $options "$attribute")
  printf '%s' "$out" | jq -c '.[].outputs'
fi
