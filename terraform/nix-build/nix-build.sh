#!/usr/bin/env bash
set -efu

declare file attribute nix_options
eval "$(jq -r '@sh "attribute=\(.attribute) file=\(.file) nix_options=\(.nix_options)"')"
if [ "${nix_options}" != '{"options":{}}' ]; then
  options=$(echo "${nix_options}" | jq -r '.options | to_entries | map("--option \(.key) \(.value)") | join(" ")')
else
  options=""
fi
if [[ -n ${file-} ]] && [[ -e ${file-} ]]; then
  # shellcheck disable=SC2086
  out=$(nix build --no-link --json $options -f "$file" "$attribute")
  printf '%s' "$out" | jq -c '.[].outputs'
else
  # shellcheck disable=SC2086
  out=$(nix build --no-link --json $options "$attribute")
  printf '%s' "$out" | jq -c '.[].outputs'
fi
