#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"

declare -A input

while IFS= read -r -d '' key && IFS= read -r -d '' value; do
  input[$key]=$value
done < <(jq -j 'to_entries[] | (.key, "\u0000", .value, "\u0000")' <<<"${ARGUMENTS}")

args=()

if [[ ${input[debug_logging]} == "true" ]]; then
  set -x
  declare -p input
  args+=("--debug")
fi
if [[ ${input[kexec_tarball_url]} != "null" ]]; then
  args+=("--kexec" "${input[kexec_tarball_url]}")
fi
if [[ ${input[build_on_remote]} == "true" ]]; then
  args+=("--build-on-remote")
fi
if [[ -n ${input[flake]} ]]; then
  args+=("--flake" "${input[flake]}")
elif [[ -n ${input[nixos_partitioner]} ]] && [[ -n ${input[nixos_system]} ]]; then
  args+=("--store-paths" "${input[nixos_partitioner]}" "${input[nixos_system]}")
fi
# Note: for kexec-only phase, neither flake nor store-paths are needed
if [[ -n ${input[nixos_generate_config_path]} ]]; then
  if [[ -n ${input[nixos_facter_path]} ]]; then
    echo "cannot set both variables 'nixos_generate_config_path' and 'nixos_facter_path'!" >&2
    exit 1
  fi
  args+=("--generate-hardware-config" "nixos-generate-config" "${input[nixos_generate_config_path]}")
elif [[ -n ${input[nixos_facter_path]} ]]; then
  args+=("--generate-hardware-config" "nixos-facter" "${input[nixos_facter_path]}")
fi
args+=(--phases "${input[phases]}")
if [[ ${input[ssh_private_key]} != null ]]; then
  export SSH_PRIVATE_KEY="${input[ssh_private_key]}"
fi
if [[ ${input[target_pass]} != null ]]; then
  export SSHPASS=${input[target_pass]}
  args+=("--env-password")
fi
if [[ ${input[copy_host_keys]} == "true" ]]; then
  args+=("--copy-host-keys")
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

nix run --extra-experimental-features 'nix-command flakes' "path:${SCRIPT_DIR}/../..#nixos-anywhere" -- "${args[@]}"
