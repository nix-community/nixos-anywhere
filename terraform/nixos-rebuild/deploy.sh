#!/usr/bin/env bash

set -uex -o pipefail

if [ "$#" -ne 6 ]; then
  echo "USAGE: $0 NIXOS_SYSTEM TARGET_USER TARGET_HOST TARGET_PORT IGNORE_SYSTEMD_ERRORS INSTALL_BOOTLOADER" >&2
  exit 1
fi

NIXOS_SYSTEM=$1
TARGET_USER=$2
TARGET_HOST=$3
TARGET_PORT=$4
IGNORE_SYSTEMD_ERRORS=$5
INSTALL_BOOTLOADER=$6

shift 6

TARGET="${TARGET_USER}@${TARGET_HOST}"

workDir=$(mktemp -d)
trap 'rm -rf "$workDir"' EXIT

sshOpts=(-p "${TARGET_PORT}")
sshOpts+=(-o UserKnownHostsFile=/dev/null)
sshOpts+=(-o StrictHostKeyChecking=no)

set +x
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
set -x

try=1
until NIX_SSHOPTS="${sshOpts[*]}" nix copy -s --experimental-features nix-command --to "ssh://$TARGET" "$NIXOS_SYSTEM"; do
  if [[ $try -gt 10 ]]; then
    echo "retries exhausted" >&2
    exit 1
  fi
  sleep 10
  try=$((try + 1))
done

if [[ $INSTALL_BOOTLOADER == "true" ]]; then
  extra_env='NIXOS_INSTALL_BOOTLOADER=1'
else
  extra_env=''
fi

switchCommand="nix-env -p /nix/var/nix/profiles/system --set $(printf "%q" "$NIXOS_SYSTEM"); $extra_env /nix/var/nix/profiles/system/bin/switch-to-configuration switch"

if [[ $TARGET_USER != "root" ]]; then
  switchCommand="sudo bash -c '$switchCommand'"
fi
deploy_status=0
# shellcheck disable=SC2029
ssh "${sshOpts[@]}" "$TARGET" "$switchCommand" || deploy_status="$?"
if [[ $IGNORE_SYSTEMD_ERRORS == "true" && $deploy_status == "4" ]]; then
  exit 0
fi
exit "$deploy_status"
