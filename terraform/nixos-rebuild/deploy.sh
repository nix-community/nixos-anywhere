#!/usr/bin/env bash

set -uex -o pipefail

if [ "$#" -ne 4 ]; then
  echo "USAGE: $0 NIXOS_SYSTEM TARGET_USER TARGET_HOST TARGET_PORT" >&2
  exit 1
fi

NIXOS_SYSTEM=$1
TARGET_USER=$2
TARGET_HOST=$3
TARGET_PORT=$4
shift 3

TARGET="${TARGET_USER}@${TARGET_HOST}"

workDir=$(mktemp -d)
trap 'rm -rf "$workDir"' EXIT

sshOpts=(-p "${TARGET_PORT}")
sshOpts+=(-o UserKnownHostsFile=/dev/null)
sshOpts+=(-o StrictHostKeyChecking=no)

if [[ -n ${SSH_KEY+x} && ${SSH_KEY} != "-" ]]; then
  sshPrivateKeyFile="$workDir/ssh_key"
  # Create the file with 0700 - umask calculation: 777 - 700 = 077
  (
    umask 077
    echo "$SSH_KEY" >"$sshPrivateKeyFile"
  )
  unset SSH_AUTH_SOCK # don't use system agent if key was supplied
  sshOpts+=(-o "IdentityFile=${sshPrivateKeyFile}")
fi

try=1
until NIX_SSHOPTS="${sshOpts[*]}" nix copy -s --experimental-features nix-command --to "ssh://$TARGET" "$NIXOS_SYSTEM"; do
  if [[ $try -gt 10 ]]; then
    echo "retries exhausted" >&2
    exit 1
  fi
  sleep 10
  try=$((try + 1))
done

switchCommand="nix-env -p /nix/var/nix/profiles/system --set $(printf "%q" "$NIXOS_SYSTEM"); /nix/var/nix/profiles/system/bin/switch-to-configuration switch"
if [[ $TARGET_USER != "root" ]]; then
  switchCommand="sudo bash -c '$switchCommand'"
fi
# shellcheck disable=SC2029
ssh "${sshOpts[@]}" "$TARGET" "$switchCommand"
