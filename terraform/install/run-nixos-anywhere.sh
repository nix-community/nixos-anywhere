#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
args=()

if [[ ${debug_logging-} == "true" ]]; then
  set -x
  args+=("--debug")
fi
if [[ ${stop_after_disko-} == "true" ]]; then
  args+=("--stop-after-disko")
fi
if [[ ${kexec_tarball_url-} != "" ]]; then
  args+=("--kexec" "${kexec_tarball_url}")
fi
if [[ ${no_reboot-} == "true" ]]; then
  args+=("--no-reboot")
fi
if [[ ${build_on_remote-} == "true" ]]; then
  args+=("--build-on-remote")
fi
if [[ -n ${flake-} ]]; then
  args+=("--flake" "${flake}")
else
  args+=("--store-paths" "${nixos_partitioner}" "${nixos_system}")
fi

tmpdir=$(mktemp -d)
cleanup() {
  rm -rf "${tmpdir}"
}
trap cleanup EXIT

if [[ ${extra_files_script-} != "" ]]; then
  if [[ ! -f ${extra_files_script} ]]; then
    echo "extra_files_script '${extra_files_script}' does not exist"
    exit 1
  fi
  if [[ ! -x ${extra_files_script} ]]; then
    echo "extra_files_script '${extra_files_script}' is not executable"
    exit 1
  fi
  extra_files_script=$(realpath "${extra_files_script}")
  mkdir "${tmpdir}/extra-files"
  pushd "${tmpdir}/extra-files"
  $extra_files_script
  popd
  args+=("--extra-files" "${tmpdir}/extra-files")
fi

args+=("-p" "${target_port}")
args+=("${target_user}@${target_host}")

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
  mkdir "${tmpdir}/keys"
  "$2" >"${tmpdir}/keys/$keyIdx"
  args+=("--disk-encryption-keys" "$1" "${tmpdir}/keys/$keyIdx")
  shift
  shift
  keyIdx=$((keyIdx + 1))
done

nix run --extra-experimental-features 'nix-command flakes' "path:${SCRIPT_DIR}/../..#nixos-anywhere" -- "${args[@]}"
