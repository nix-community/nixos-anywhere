showUsage() {
  cat <<USAGE
Usage: nixos-anywhere [options] ssh-host

Options:

* -f, --flake flake
  set the flake to install the system from
* -L, --print-build-logs
  print full build logs
* -s, --store-paths
  set the store paths to the disko-script and nixos-system directly
  if this is give, flake is not needed
* --no-reboot
  do not reboot after installation, allowing further customization of the target installation.
* --kexec url
  use another kexec tarball to bootstrap NixOS
* --stop-after-disko
  exit after disko formating, you can then proceed to install manually or some other way
* --extra-files files
  files to copy into the new nixos installation
* --disk-encryption-keys remote_path local_path
  copy the contents of the file or pipe in local_path to remote_path in the installer environment,
  after kexec but before installation. Can be repeated.
* --no-substitute-on-destination
  disable passing --substitute-on-destination to nix-copy
* --debug
  enable debug output
* --option KEY VALUE
  nix option to pass to every nix related command
* --from store-uri
  URL of the source Nix store to copy the nixos and disko closure from
* --build-on-remote
  build the closure on the remote machine instead of locally and copy-closuring it
USAGE
}

abort() {
  echo "aborted: $*" >&2
  exit 1
}

warn() {
  echo "warning: $*" >&2
}

default_kexec_url=https://github.com/nix-community/nixos-images/releases/download/nixos-22.11/nixos-kexec-installer-x86_64-linux.tar.gz
kexec_url="$default_kexec_url"
enable_debug=""
maybe_reboot="sleep 6 && reboot"
nix_options=(
  --extra-experimental-features 'nix-command flakes'
  "--no-write-lock-file"
)
substitute_on_destination=y

declare -A disk_encryption_keys
declare -a nix_copy_options
declare -a ssh_copy_id_args

while [[ $# -gt 0 ]]; do
  case "$1" in
  -f | --flake)
    flake=$2
    shift
    ;;
  -L | --print-build-logs)
    print_build_logs=y
    ;;
  -s | --store-paths)
    disko_script=$(readlink -f "$2")
    nixos_system=$(readlink -f "$3")
    shift
    shift
    ;;
  --help)
    showUsage
    exit 0
    ;;
  --kexec)
    kexec_url=$2
    shift
    ;;
  --debug)
    enable_debug="-x"
    print_build_logs=y
    set -x
    ;;
  --extra-files)
    extra_files=$2
    shift
    ;;
  --disk-encryption-keys)
    disk_encryption_keys["$2"]="$3"
    shift
    shift
    ;;
  --stop-after-disko)
    stop_after_disko=y
    ;;
  --no-reboot)
    maybe_reboot=""
    ;;
  --from)
    nix_copy_options+=("--from" "$2")
    shift
    ;;
  --option)
    key=$2
    shift
    value=$2
    shift
    nix_options+=("--option" "$key" "$value")
    ;;
  --no-substitute-on-destination)
    substitute_on_destination=n
    ;;
  --build-on-remote)
    build_on_remote=y
    ;;

  *)
    if [[ -z ${ssh_connection-} ]]; then
      ssh_connection="$1"
    else
      showUsage
      exit 1
    fi
    ;;
  esac
  shift
done

if [[ ${print_build_logs-n} == "y" ]]; then
  nix_options+=("-L")
fi

if [[ ${substitute_on_destination-n} == "y" ]]; then
  nix_copy_options+=("--substitute-on-destination")
fi

# ssh wrapper
timeout_ssh_() {
  timeout 10 ssh -i "$ssh_key_dir"/nixos-anywhere -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "$ssh_connection" "$@"
}
ssh_() {
  ssh -T -i "$ssh_key_dir"/nixos-anywhere -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "$ssh_connection" "$@"
}
install_binary_to_host() {
  local target_binary="$1"
  local local_binary="$2"
  ssh_ "mkdir -p ${...} && cat > $1 && chmod +x $1" < "$2"
}

nix_copy() {
  NIX_SSHOPTS="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $ssh_key_dir/nixos-anywhere" nix copy \
    "${nix_options[@]}" \
    "${nix_copy_options[@]}" \
    "$@"
}
nix_build() {
  NIX_SSHOPTS="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $ssh_key_dir/nixos-anywhere" nix build \
    --print-out-paths \
    --no-link \
    "${nix_options[@]}" \
    "$@"
}

if [[ -z ${ssh_connection-} ]]; then
  abort "ssh-host must be set"
fi

# we generate a temporary ssh keypair that we can use during nixos-anywhere
ssh_key_dir=$(mktemp -d)
trap 'rm -rf "$ssh_key_dir"' EXIT
mkdir -p "$ssh_key_dir"
ssh-keygen -t ed25519 -f "$ssh_key_dir"/nixos-anywhere -P "" -C "nixos-anywhere" >/dev/null

# parse flake nixos-install style syntax, get the system attr
if [[ -n ${flake-} ]]; then
  if [[ $flake =~ ^(.*)\#([^\#\"]*)$ ]]; then
    flake="${BASH_REMATCH[1]}"
    flakeAttr="${BASH_REMATCH[2]}"
  fi
  if [[ -z ${flakeAttr-} ]]; then
    echo "Please specify the name of the NixOS configuration to be installed, as a URI fragment in the flake-uri." >&2
    echo 'For example, to use the output nixosConfigurations.foo from the flake.nix, append "#foo" to the flake-uri.' >&2
    exit 1
  fi
  if [[ ${build_on_remote-n} == "n" ]]; then
    disko_script=$(nix_build "${flake}#nixosConfigurations.\"${flakeAttr}\".config.system.build.disko")
    nixos_system=$(nix_build "${flake}#nixosConfigurations.\"${flakeAttr}\".config.system.build.toplevel")
  fi
elif [[ -n ${disko_script-} ]] && [[ -n ${nixos_system-} ]]; then
  if [[ ! -e ${disko_script} ]] || [[ ! -e ${nixos_system} ]]; then
    abort "${disko_script} and ${nixos_system} must be existing store-paths"
  fi
  :
else
  abort "flake must be set"
fi

if [[ -n ${SSH_PRIVATE_KEY-} ]]; then
  sshPrivateKeyFile=$(mktemp)
  trap 'rm "$sshPrivateKeyFile"' EXIT
  (
    umask 077
    printf '%s\n' "$SSH_PRIVATE_KEY" >"$sshPrivateKeyFile"
  )
  unset SSH_AUTH_SOCK # don't use system agent if key was supplied
  ssh_copy_id_args+=(-o "IdentityFile=${sshPrivateKeyFile}")
  ssh_copy_id_args+=(-f)
fi

until
  ssh-copy-id \
    -i "$ssh_key_dir"/nixos-anywhere.pub \
    -o ConnectTimeout=10 \
    -o UserKnownHostsFile=/dev/null \
    -o StrictHostKeyChecking=no \
    "${ssh_copy_id_args[@]}" \
    "$ssh_connection"
do
  sleep 3
done

import_facts() {
  local facts filtered_facts
  if ! facts=$(
    ssh_ -o ConnectTimeout=10 -- <<SSH
set -efu ${enable_debug}
has(){
  command -v "\$1" >/dev/null && echo "y" || echo "n"
}
is_nixos=\$(if test -f /etc/os-release && grep -q ID=nixos /etc/os-release; then echo "y"; else echo "n"; fi)
cat <<FACTS
is_os=\$(uname)
is_arch=\$(uname -m)
is_kexec=\$(if test -f /etc/is_kexec; then echo "y"; else echo "n"; fi)
is_nixos=\$is_nixos
is_installer=\$(if [[ "\$is_nixos" == "y" ]] && grep -q VARIANT_ID=installer /etc/os-release; then echo "y"; else echo "n"; fi)
has_tar=\$(has tar)
has_sudo=\$(has sudo)
has_wget=\$(has wget)
has_curl=\$(has curl)
has_setsid=\$(has setsid)
has_bash=\$(has bash)
FACTS
SSH
  ); then
    exit 1
  fi
  filtered_facts=$(echo "$facts" | grep -E '^(has|is)_[a-z0-9_]+=\S+')
  if [[ -z $filtered_facts ]]; then
    abort "Retrieving host facts via ssh failed. Check with --debug for the root cause, unless you have done so already"
  fi
  # make facts available in script
  # shellcheck disable=SC2046
  export $(echo "$filtered_facts" | xargs)
}

import_facts

tar_="tar"
if [[ ${has_tar-n} == "n" ]]; then
  warn "no tar command found, but required to unpack kexec tarball; will polyfill with a Nix-built static binary: \`pkgsStatic.gnutar\` "
  tar_="/root/nixos-anywhere-binaries/tar"
  install_binary_to_host ${tar_} "$(nix_build "nixpkgs#pkgsStatic.gnutar" --no-out-link)/tar"
fi

# We cannot polyfill it, I don't know where it's used.
if [[ ${has_bash-n} == "n" ]]; then
  warn "no bash command found, but required for running the reboot script"
fi

setsid_="setsid"
if [[ ${has_setsid-n} == "n" ]]; then
  abort "no setsid command found, but required to run the kexec script under a new session; will polyfill with a Nix-built static binary: \`pkgsStatic.busybox\`"
  setsid_="/root/nixos-anywhere-binaries/setsid"
  install_binary_to_host ${setsid_} "$(nix_build "nixpkgs#pkgsStatic.busybox" --no-out-link)/setsid"
fi

maybe_sudo=""
if [[ ${has_sudo-n} == "y" ]]; then
  maybe_sudo="sudo"
fi

if [[ ${is_os-n} != "Linux" ]]; then
  abort "This script requires Linux as the operating system, but got $is_os"
fi

if [[ ${is_arch-n} != "x86_64" ]] && [[ $kexec_url == "$default_kexec_url" ]]; then
  abort "The default kexec image only support x86_64 cpus. Checkout https://github.com/numtide/nixos-anywhere/#using-your-own-kexec-image for more information."
fi

if [[ ${is_kexec-n} == "n" ]] && [[ ${is_installer-n} == "n" ]]; then
  ssh_ <<SSH
set -efu ${enable_debug}
$maybe_sudo rm -rf /root/kexec
$maybe_sudo mkdir -p /root/kexec
SSH

  if [[ -f $kexec_url ]]; then
    ssh_ "${maybe_sudo} ${tar_} -C /root/kexec -xvzf-" <"$kexec_url"
  elif [[ ${has_curl-n} == "y" ]]; then
    ssh_ "curl --fail -Ss -L '${kexec_url}' | ${maybe_sudo} ${tar_} -C /root/kexec -xvzf-"
  elif [[ ${has_wget-n} == "y" ]]; then
    ssh_ "wget '${kexec_url}' -O- | ${maybe_sudo} ${tar_} -C /root/kexec -xvzf-"
  else
    curl --fail -Ss -L "${kexec_url}" | ssh_ "${maybe_sudo} ${tar_} -C /root/kexec -xvzf-"
  fi

  ssh_ <<SSH
TMPDIR=/root/kexec ${setsid_} ${maybe_sudo} /root/kexec/kexec/run
SSH

  # wait for machine to become unreachable
  while timeout_ssh_ -- exit 0; do sleep 1; done

  # After kexec we explicitly set the user to root@
  ssh_connection="root@${ssh_connection#*@}"

  # watiting for machine to become available again
  until ssh_ -o ConnectTimeout=10 -- exit 0; do sleep 5; done
fi
for path in "${!disk_encryption_keys[@]}"; do
  echo "Uploading ${disk_encryption_keys[$path]} to $path"
  ssh_ "umask 077; cat > $path" <"${disk_encryption_keys[$path]}"
done

pubkey=$(ssh-keyscan -t ed25519 "${ssh_connection//*@/}" 2>/dev/null | sed -e 's/^[^ ]* //' | base64 -w0)

if [[ -z ${disko_script-} ]] && [[ ${build_on_remote-n} == "y" ]]; then
  disko_script=$(
    nix_build "${flake}#nixosConfigurations.\"${flakeAttr}\".config.system.build.disko" \
      --builders "ssh://$ssh_connection?base64-ssh-public-host-key=$pubkey&ssh-key=$ssh_key_dir/nixos-anywhere $is_arch-linux"
  )
fi
nix_copy --to "ssh://$ssh_connection" "$disko_script"
ssh_ "$disko_script"

if [[ ${stop_after_disko-n} == "y" ]]; then
  # Should we also do this for `--no-reboot`?
  echo "WARNING: leaving temporary ssh key at '$ssh_key_dir/nixos-anywhere' to login to the machine" >&2
  trap - EXIT
  exit 0
fi

if [[ -z ${nixos_system-} ]] && [[ ${build_on_remote-n} == "y" ]]; then
  nixos_system=$(
    nix_build "${flake}#nixosConfigurations.\"${flakeAttr}\".config.system.build.toplevel" \
      --builders "ssh://$ssh_connection?remote-store=local?root=/mnt&base64-ssh-public-host-key=$pubkey&ssh-key=$ssh_key_dir/nixos-anywhere $is_arch-linux"
  )
fi
nix_copy --to "ssh://$ssh_connection?remote-store=local?root=/mnt" "$nixos_system"

if [[ -n ${extra_files-} ]]; then
  if [[ -d $extra_files ]]; then
    extra_files="$extra_files/"
  fi
  rsync -rlpv -FF -e "ssh -i \"$ssh_key_dir\"/nixos-anywhere -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" "$extra_files" "${ssh_connection}:/mnt/"
fi

ssh_ <<SSH
set -efu ${enable_debug}
# needed for installation if initrd-secrets are used
mkdir -p /mnt/tmp
chmod 777 /mnt/tmp
nixos-install --no-root-passwd --no-channel-copy --system "$nixos_system"
# We will reboot in background so we can cleanly finish the script before the hosts go down.
# This makes integration into scripts easier
nohup bash -c '${maybe_reboot}' >/dev/null &
SSH

# wait for machine to become unreachable due to reboot
if [[ -n ${maybe_reboot} ]]; then
  while timeout_ssh_ -- exit 0; do sleep 1; done
fi
