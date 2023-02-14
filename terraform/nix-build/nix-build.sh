#!/usr/bin/env -S nix --extra-experimental-features 'nix-command flakes' shell --inputs-from path:../../ nixpkgs#jq nixpkgs#nix nixpkgs#coreutils nixpkgs#runtimeShellPackage -c bash
set -efu

declare file attribute
eval "$(jq -r '@sh "attribute=\(.attribute) file=\(.file)"')"
if [[ -n ${file-} ]] && [[ -e ${file-} ]]; then
  out=$(nix build --no-link --json -f "$file" "$attribute")
  printf '%s' "$out" | jq -c '.[].outputs'
else
  out=$(nix build --no-link --json "$attribute")
  printf '%s' "$out" | jq -c '.[].outputs'
fi
