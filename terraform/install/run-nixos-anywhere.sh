# shellcheck shell=bash
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
args+=("--store-paths" "${nixos_partitioner} ${nixos_system}")
if [[ ${extra_files_script-} != "" ]]; then
  tmpdir=$(mktemp -d)
  cleanup() {
    rm -rf "${tmpdir}"
  }
  trap cleanup EXIT
  pushd "${tmpdir}"
  ${extra_files_script}
  popd
  args+=("--extra-files" "${tmpdir}")
fi
args+=("${target_user}@${target_host}")

nix run --extra-experimental-features 'nix-command flakes' "path:${SCRIPT_DIR}/../..#nixos-anywhere" -- "${args[@]}"
