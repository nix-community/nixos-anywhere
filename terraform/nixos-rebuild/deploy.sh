#!/usr/bin/env bash

set -uex -o pipefail

if [ "$#" -ne 4 ]; then
  echo "USAGE: $0 NIXOS_SYSTEM TARGET_HOST TARGET_PORT USE_SUDO" >&2
  exit 1
fi

NIXOS_SYSTEM=$1
TARGET_HOST=$2
TARGET_PORT=$3
USE_SUDO=$4
shift 4

workDir=$(mktemp -d)
trap 'rm -rf "$workDir"' EXIT

sshOpts=(-p "${TARGET_PORT}")
sshOpts+=(-o UserKnownHostsFile=/dev/null)
sshOpts+=(-o StrictHostKeyChecking=no)

maybesudo=""
if [[ "$USE_SUDO" == "1" ]]; then
  maybesudo="sudo"
fi

if [[ -n ${SSH_KEY+x} && ${SSH_KEY} != "-" ]]; then
  sshPrivateKeyFile="$workDir/ssh_key"
  trap 'rm "$sshPrivateKeyFile"' EXIT
  echo "$SSH_KEY" >"$sshPrivateKeyFile"
  chmod 0700 "$sshPrivateKeyFile"
  unset SSH_AUTH_SOCK # don't use system agent if key was supplied
  sshOpts+=(-o "IdentityFile=${sshPrivateKeyFile}")
fi

try=1
until NIX_SSHOPTS="${sshOpts[*]}" nix copy -s --experimental-features nix-command --to "ssh://$TARGET_HOST" "$NIXOS_SYSTEM"; do
  if [[ $try -gt 10 ]]; then
    echo "retries exhausted" >&2
    exit 1
  fi
  sleep 10
  try=$((try + 1))
done


# shellcheck disable=SC2029
ssh "${sshOpts[@]}" "$TARGET_HOST" "${maybesudo} nix-env -p /nix/var/nix/profiles/system --set $(printf "%q" "$NIXOS_SYSTEM"); ${maybesudo} /nix/var/nix/profiles/system/bin/switch-to-configuration switch" || :
