#!/usr/bin/env -S nix --extra-experimental-features 'nix-command flakes' shell --inputs-from path:../../ nixpkgs#nix nixpkgs#coreutils nixpkgs#runtimeShellPackage -c bash

set -uex -o pipefail

if [ "$#" -ne 3 ]; then
  echo "USAGE: $0 NIXOS_SYSTEM TARGET_HOST TARGET_PORT" >&2
  exit 1
fi

NIXOS_SYSTEM=$1
TARGET_HOST=$2
TARGET_PORT=$3
shift 3

workDir=$(mktemp -d)
trap 'rm -rf "$workDir"' EXIT

sshOpts=(-p "${TARGET_PORT}")
sshOpts+=(-o UserKnownHostsFile=/dev/null)
sshOpts+=(-o StrictHostKeyChecking=no)

if [[ -n ${SSH_KEY+x} && ${SSH_KEY} != "-" ]]; then
  sshPrivateKeyFile="$workDir/ssh_key"
  trap 'rm "$sshPrivateKeyFile"' EXIT
  echo "$SSH_KEY" >"$sshPrivateKeyFile"
  chmod 0700 "$sshPrivateKeyFile"
  unset SSH_AUTH_SOCK # don't use system agent if key was supplied
  sshOpts+=(-o "IdentityFile=${sshPrivateKeyFile}")
fi

try=1
until NIX_SSHOPTS="${sshOpts[*]}" nix copy -s --extra-experimental-features 'nix-command flakes' --to "ssh://$TARGET_HOST" "$NIXOS_SYSTEM"; do
  if [[ $try -gt 10 ]]; then
    echo "retries exhausted" >&2
    exit 1
  fi
  sleep 10
  try=$((try + 1))
done

# shellcheck disable=SC2029
ssh "${sshOpts[@]}" "$TARGET_HOST" "nix-env -p /nix/var/nix/profiles/system --set $(printf "%q" "$NIXOS_SYSTEM"); /nix/var/nix/profiles/system/bin/switch-to-configuration switch" || :
