#!/usr/bin/env bash
set -efu

declare file attribute nix_options environment
eval "$(jq -r '@sh "attribute=\(.attribute) file=\(.file) nix_options=\(.nix_options) environment=\(.environment)"')"
options=$(echo "${nix_options}" | jq -r '.options | to_entries | map("--option \(.key) \(.value)") | join(" ")')
vars=$(echo "${environment}" | jq -r "to_entries | map(\"\(.key)='\(.value)'\") | join(\" \")")
if [[ -n ${file-} ]] && [[ -e ${file-} ]]; then
  # shellcheck disable=SC2086
  out=$(eval "env ${vars} nix build --no-link --json --impure $options -f '$file' '$attribute'")
  printf '%s' "$out" | jq -c '.[].outputs'
else
  # shellcheck disable=SC2086
  out=$(eval "env ${vars} nix build --no-link --json --impure $options '$attribute'")
  printf '%s' "$out" | jq -c '.[].outputs'
fi
