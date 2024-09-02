#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"

declare -A input

while IFS= read -r -d '' key && IFS= read -r -d '' value; do
  input[$key]=$value
done < <(jq -j 'to_entries[] | (.key, "\u0000", .value, "\u0000")' <<<"$ARGUMENTS")

args=()

if [[ ${input[debug_logging]} == "true" ]]; then
  set -x
  declare -p input
  args+=("--debug")
fi
if [[ ${input[stop_after_disko]} == "true" ]]; then
  args+=("--stop-after-disko")
fi
if [[ ${input[kexec_tarball_url]} != "null" ]]; then
  args+=("--kexec" "${input[kexec_tarball_url]}")
fi
if [[ ${input[no_reboot]} == "true" ]]; then
  args+=("--no-reboot")
fi
if [[ ${input[build_on_remote]} == "true" ]]; then
  args+=("--build-on-remote")
fi
if [[ -n ${input[flake]} ]]; then
  args+=("--flake" "${input[flake]}")
else
  args+=("--store-paths" "${input[nixos_partitioner]}" "${input[nixos_system]}")
fi

tmpdir=$(mktemp -d)
cleanup() {
  rm -rf "${tmpdir}"
}
trap cleanup EXIT

if [[ ${input[extra_files_script]} != "null" ]]; then
  if [[ ! -f ${input[extra_files_script]} ]]; then
    echo "extra_files_script '${input[extra_files_script]}' does not exist"
    exit 1
  fi
  if [[ ! -x ${input[extra_files_script]} ]]; then
    echo "extra_files_script '${input[extra_files_script]}' is not executable"
    exit 1
  fi
  extra_files_script=$(realpath "${input[extra_files_script]}")
  mkdir "${tmpdir}/extra-files"
  pushd "${tmpdir}/extra-files"
  $extra_files_script
  popd
  args+=("--extra-files" "${tmpdir}/extra-files")
fi

args+=("-p" "${input[target_port]}")
args+=("${input[target_user]}@${input[target_host]}")

keyIdx=0
while [[ $# -gt 0 ]]; do
  if [[ ! -f $2 ]]; then
    echo "Script file '$2' does not exist"
    exit 1
  fi
  if [[ ! -x $2 ]]; then
    echo "Script file '$2' is not executable"
    exit 1
  fi
  mkdir -p "${tmpdir}/keys"
  "$2" >"${tmpdir}/keys/$keyIdx"
  args+=("--disk-encryption-keys" "$1" "${tmpdir}/keys/$keyIdx")
  shift
  shift
  keyIdx=$((keyIdx + 1))
done

SSH_PRIVATE_KEY="${input[ssh_private_key]}" nix run --extra-experimental-features 'nix-command flakes' "path:${SCRIPT_DIR}/../..#nixos-anywhere" -- "${args[@]}"
