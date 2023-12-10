#!/usr/bin/env bash
set -euo pipefail

showUsage() {
  cat <<USAGE
Usage: nixos-anywhere [options] <ssh-host>

Options:

* -f, --flake <flake_uri>
  set the flake to install the system from.
* -i <identity_file>
  selects which SSH private key file to use.
* -p, --ssh-port <ssh_port>
  set the ssh port to connect with
* --ssh-option <ssh_option>
  set an ssh option
* -L, --print-build-logs
  print full build logs
* -s, --store-paths <disko-script> <nixos-system>
  set the store paths to the disko-script and nixos-system directly
  if this is give, flake is not needed
* -t --tty
  Force pseudo-terminal allocation in SSH sessions. Use this when you expect e.g.
  to be asked for password entry during LUKS configuration.
* --no-reboot
  do not reboot after installation, allowing further customization of the target installation.
* --kexec <path>
  use another kexec tarball to bootstrap NixOS
* --post-kexec-ssh-port <ssh_port>
  after kexec is executed, use a custom ssh port to connect. Defaults to 22
* --copy-host-keys
  copy over existing /etc/ssh/ssh_host_* host keys to the installation
* --stop-after-disko
  exit after disko formatting, you can then proceed to install manually or some other way
* --extra-files <file...>
  files to copy into the new nixos installation
* --disk-encryption-keys <remote_path> <local_path>
  copy the contents of the file or pipe in local_path to remote_path in the installer environment,
  after kexec but before installation. Can be repeated.
* --no-substitute-on-destination
  disable passing --substitute-on-destination to nix-copy
* --debug
  enable debug output
* --option <key> <value>
  nix option to pass to every nix related command
* --from <store-uri>
  URL of the source Nix store to copy the nixos and disko closure from
* --build-on-remote
  build the closure on the remote machine instead of locally and copy-closuring it
* --vm-test
  build the system and test the disk configuration inside a VM without installing it to the target.
USAGE
}

abort() {
  echo "aborted: $*" >&2
  exit 1
}

step() {
  echo "### $* ###"
}

kexec_url=""
enable_debug=""
maybe_reboot="sleep 6 && reboot"
nix_options=(
  --extra-experimental-features 'nix-command flakes'
  "--no-write-lock-file"
)
substitute_on_destination=y
ssh_private_key_file=
ssh_tty_param="-T"
post_kexec_ssh_port=22

declare -A disk_encryption_keys
declare -a nix_copy_options
declare -a ssh_copy_id_args
declare -a ssh_args

while [[ $# -gt 0 ]]; do
  case "$1" in
  -f | --flake)
    flake=$2
    shift
    ;;
  -i)
    ssh_private_key_file=$2
    shift
    ;;
  -p | --ssh-port)
    ssh_args+=("-p" "$2")
    shift
    ;;
  --ssh-option)
    ssh_args+=("-o" "$2")
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
  -t | --tty)
    ssh_tty_param="-t"
    ;;
  --help)
    showUsage
    exit 0
    ;;
  --kexec)
    kexec_url=$2
    shift
    ;;
  --post-kexec-ssh-port)
    post_kexec_ssh_port=$2
    shift
    ;;
  --copy-host-keys)
    copy_host_keys=y
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
  --vm-test)
    vm_test=y
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
  timeout 10 ssh -i "$ssh_key_dir"/nixos-anywhere -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "${ssh_args[@]}" "$ssh_connection" "$@"
}
ssh_() {
  ssh "$ssh_tty_param" -i "$ssh_key_dir"/nixos-anywhere -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "${ssh_args[@]}" "$ssh_connection" "$@"
}

nix_copy() {
  NIX_SSHOPTS="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $ssh_key_dir/nixos-anywhere ${ssh_args[*]}" nix copy \
    "${nix_options[@]}" \
    "${nix_copy_options[@]}" \
    "$@"
}
nix_build() {
  NIX_SSHOPTS="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $ssh_key_dir/nixos-anywhere ${ssh_args[*]}" nix build \
    --print-out-paths \
    --no-link \
    "${nix_options[@]}" \
    "$@"
}

if [[ -z ${vm_test-} ]]; then
  if [[ -z ${ssh_connection-} ]]; then
    abort "ssh-host must be set"
  fi

  # we generate a temporary ssh keypair that we can use during nixos-anywhere
  ssh_key_dir=$(mktemp -d)
  trap 'rm -rf "$ssh_key_dir"' EXIT
  mkdir -p "$ssh_key_dir"
  # ssh-copy-id requires this directory
  mkdir -p "$HOME/.ssh/"
  ssh-keygen -t ed25519 -f "$ssh_key_dir"/nixos-anywhere -P "" -C "nixos-anywhere" >/dev/null
fi

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
    if [[ -n ${vm_test-} ]]; then
      if [[ -n ${extra_files-} ]]; then
        echo "--vm-test is not supported with --extra-files" >&2
        exit 1
      fi
      if [[ -n ${disk_encryption_keys-} ]]; then
        echo "--vm-test is not supported with --disk-encryption-keys" >&2
        exit 1
      fi
      exec nix build \
        --print-out-paths \
        --no-link \
        -L \
        "${nix_options[@]}" \
        "${flake}#nixosConfigurations.\"${flakeAttr}\".config.system.build.installTest"
    fi
    disko_script=$(nix_build "${flake}#nixosConfigurations.\"${flakeAttr}\".config.system.build.diskoScript")
    nixos_system=$(nix_build "${flake}#nixosConfigurations.\"${flakeAttr}\".config.system.build.toplevel")
  fi
elif [[ -n ${disko_script-} ]] && [[ -n ${nixos_system-} ]]; then
  if [[ -n ${vm_test-} ]]; then
    echo "vm-test is not supported with --store-paths" >&2
    echo "Please use --flake instead or build config.system.build.installTest of your nixos configuration manually" >&2
    exit 1
  fi
  if [[ ! -e ${disko_script} ]] || [[ ! -e ${nixos_system} ]]; then
    abort "${disko_script} and ${nixos_system} must be existing store-paths"
  fi
else
  abort "flake must be set"
fi

# overrides -i if passed as an env var
if [[ -n ${SSH_PRIVATE_KEY-} ]]; then
  # $ssh_key_dir is getting deleted on trap EXIT
  ssh_private_key_file="$ssh_key_dir/from-env"
  (
    umask 077
    printf '%s\n' "$SSH_PRIVATE_KEY" >"$ssh_private_key_file"
  )
fi

if [[ -n ${ssh_private_key_file-} ]]; then
  unset SSH_AUTH_SOCK # don't use system agent if key was supplied
  ssh_copy_id_args+=(-o "IdentityFile=${ssh_private_key_file}")
  ssh_copy_id_args+=(-f)
fi

ssh_settings=$(ssh "${ssh_args[@]}" -G "${ssh_connection}")
ssh_host=$(echo "$ssh_settings" | awk '/^hostname / { print $2 }')
ssh_port=$(echo "$ssh_settings" | awk '/^port / { print $2 }')

step Uploading install SSH keys
until
  ssh-copy-id \
    -i "$ssh_key_dir"/nixos-anywhere.pub \
    -o ConnectTimeout=10 \
    -o UserKnownHostsFile=/dev/null \
    -o StrictHostKeyChecking=no \
    "${ssh_copy_id_args[@]}" \
    "${ssh_args[@]}" \
    "$ssh_connection"
do
  sleep 3
done

import_facts() {
  local facts filtered_facts
  if ! facts=$(
    ssh_ -o ConnectTimeout=10 bash -- <<SSH
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

step Gathering machine facts
import_facts

if [[ ${has_tar-n} == "n" ]]; then
  abort "no tar command found, but required to unpack kexec tarball"
fi

if [[ ${has_setsid-n} == "n" ]]; then
  abort "no setsid command found, but required to run the kexec script under a new session"
fi

maybe_sudo=""
if [[ ${has_sudo-n} == "y" ]]; then
  maybe_sudo="sudo"
fi

if [[ ${is_os-n} != "Linux" ]]; then
  abort "This script requires Linux as the operating system, but got $is_os"
fi

if [[ ${is_kexec-n} == "n" ]] && [[ ${is_installer-n} == "n" ]]; then
  if [[ $kexec_url == "" ]]; then
    case "${is_arch-unknown}" in
    x86_64 | aarch64)
      kexec_url="https://github.com/nix-community/nixos-images/releases/download/nixos-23.11/nixos-kexec-installer-noninteractive-${is_arch}-linux.tar.gz"
      ;;
    *)
      abort "Unsupported architecture: ${is_arch}. Our default kexec images only support x86_64 and aarch64 cpus. Checkout https://github.com/nix-community/nixos-anywhere/#using-your-own-kexec-image for more information."
      ;;
    esac
  fi

  step Switching system into kexec
  ssh_ bash <<SSH
set -efu ${enable_debug}
$maybe_sudo rm -rf /root/kexec
$maybe_sudo mkdir -p /root/kexec
SSH

  if [[ -f $kexec_url ]]; then
    ssh_ "${maybe_sudo} tar -C /root/kexec -xvzf-" <"$kexec_url"
  elif [[ ${has_curl-n} == "y" ]]; then
    ssh_ "curl --fail -Ss -L '${kexec_url}' | ${maybe_sudo} tar -C /root/kexec -xvzf-"
  elif [[ ${has_wget-n} == "y" ]]; then
    ssh_ "wget '${kexec_url}' -O- | ${maybe_sudo} tar -C /root/kexec -xvzf-"
  else
    curl --fail -Ss -L "${kexec_url}" | ssh_ "${maybe_sudo} tar -C /root/kexec -xvzf-"
  fi

  ssh_ <<SSH
TMPDIR=/root/kexec setsid ${maybe_sudo} /root/kexec/kexec/run
SSH

  # use the default SSH port to connect at this point
  for i in "${!ssh_args[@]}"; do
    if [[ ${ssh_args[i]} == "-p" ]]; then
      ssh_args[i + 1]=$post_kexec_ssh_port
      break
    fi
  done

  # wait for machine to become unreachable.
  while timeout_ssh_ -- exit 0; do sleep 1; done

  # After kexec we explicitly set the user to root@
  ssh_connection="root@${ssh_host}"

  # waiting for machine to become available again
  until ssh_ -o ConnectTimeout=10 -- exit 0; do sleep 5; done
fi
for path in "${!disk_encryption_keys[@]}"; do
  step "Uploading ${disk_encryption_keys[$path]} to $path"
  ssh_ "umask 077; cat > $path" <"${disk_encryption_keys[$path]}"
done

if [[ ${build_on_remote-n} == "y" ]]; then
  pubkey=$(ssh-keyscan -p "$ssh_port" -t ed25519 "$ssh_host" 2>/dev/null || {
    echo "ERROR: failed to retrieve host public key for ${ssh_connection}" >&2
    exit 1
  })
  pubkey=$(echo "$pubkey" | sed -e 's/^[^ ]* //' | base64 -w0)
fi

if [[ -z ${disko_script-} ]] && [[ ${build_on_remote-n} == "y" ]]; then
  step Building disko script
  disko_script=$(
    nix_build "${flake}#nixosConfigurations.\"${flakeAttr}\".config.system.build.diskoScript" \
      --builders "ssh://$ssh_connection $is_arch-linux $ssh_key_dir/nixos-anywhere - - - - $pubkey "
  )
fi
step Formatting hard drive with disko
nix_copy --to "ssh://$ssh_connection" "$disko_script"
ssh_ "$disko_script"

if [[ ${stop_after_disko-n} == "y" ]]; then
  # Should we also do this for `--no-reboot`?
  echo "WARNING: leaving temporary ssh key at '$ssh_key_dir/nixos-anywhere' to login to the machine" >&2
  trap - EXIT
  exit 0
fi

if [[ -z ${nixos_system-} ]] && [[ ${build_on_remote-n} == "y" ]]; then
  step Building the system closure
  nixos_system=$(
    nix_build "${flake}#nixosConfigurations.\"${flakeAttr}\".config.system.build.toplevel" \
      --builders "ssh://$ssh_connection?remote-store=local?root=/mnt $is_arch-linux $ssh_key_dir/nixos-anywhere - - - - $pubkey "
  )
fi
step Uploading the system closure
nix_copy --to "ssh://$ssh_connection?remote-store=local?root=/mnt" "$nixos_system"

if [[ -n ${extra_files-} ]]; then
  if [[ -d $extra_files ]]; then
    extra_files="$extra_files/"
  fi
  step Copying extra files
  rsync -rlpv -FF \
    -e "ssh -i \"$ssh_key_dir\"/nixos-anywhere -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${ssh_args[*]}" \
    "$extra_files" \
    "${ssh_connection}:/mnt/"
  ssh_ "chmod 755 /mnt" # rsync also changes permissions of /mnt
fi

step Installing NixOS
ssh_ bash <<SSH
set -eu ${enable_debug}
# when running not in nixos we might miss this directory, but it's needed in the nixos chroot during installation
export PATH="\$PATH:/run/current-system/sw/bin"

# needed for installation if initrd-secrets are used
mkdir -p /mnt/tmp
chmod 777 /mnt/tmp
if [[ ${copy_host_keys-n} == "y" ]]; then
  # NB we copy host keys that are in turn copied by kexec installer.
  mkdir -m 755 -p /mnt/etc/ssh
  for p in /etc/ssh/ssh_host_*; do
    # Skip if the source file does not exist (i.e. glob did not match any files)
    # or the destination already exists (e.g. copied with --extra-files).
    if [ ! -e "\$p" -o -e "/mnt/\$p" ]; then
      continue
    fi
    cp -a "\$p" "/mnt/\$p"
  done
fi
nixos-install --no-root-passwd --no-channel-copy --system "$nixos_system"
if command -v zpool >/dev/null; then
  # we always want to export the zfs pools so people can boot from it without force import
  umount -Rv /mnt/
  zpool export -a || true
fi
# We will reboot in background so we can cleanly finish the script before the hosts go down.
# This makes integration into scripts easier
nohup bash -c '${maybe_reboot}' >/dev/null &
SSH

if [[ -n ${maybe_reboot} ]]; then
  step Waiting for the machine to become reachable again
  while timeout_ssh_ -- exit 0; do sleep 1; done
fi

step "Done!"
