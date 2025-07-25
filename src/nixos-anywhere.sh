#!/usr/bin/env bash
set -euo pipefail

here=$(dirname "${BASH_SOURCE[0]}")
flake=""
flakeAttr=""
kexecUrl=""
kexecExtraFlags=""
sshStoreSettings="compress=true"
enableDebug=""
nixBuildFlags=()
diskoAttr=""
diskoScript=""
diskoMode=""
diskoDeps=y
nixosSystem=""
extraFiles=""
vmTest="n"
nixOptions=(
  --extra-experimental-features 'nix-command flakes'
  "--no-write-lock-file"
)
SSH_PRIVATE_KEY=${SSH_PRIVATE_KEY-}
machineSubstituters="y"

declare -A phases
phases[kexec]=1
phases[disko]=1
phases[install]=1
phases[reboot]=1

hardwareConfigBackend=none
hardwareConfigPath=
sshPrivateKeyFile=
if [ -t 0 ]; then # stdin is a tty, we allow interactive input to ssh i.e. passwords
  sshTtyParam="-t"
else
  sshTtyParam="-T"
fi
sshConnection=
postKexecSshPort=22
buildOnRemote=n
buildOn=auto
envPassword=n

# Facts set by get-facts.sh
isOs=
isArch=
isKexec=
isInstaller=
isContainer=
hasIpv6Only=
hasTar=
hasCpio=
hasSudo=
hasDoas=
hasWget=
hasCurl=
hasSetsid=
hasNixOSFacter=

tempDir=$(mktemp -d)
trap 'rm -rf "$tempDir"' EXIT
mkdir -p "$tempDir"

declare -A diskEncryptionKeys=()
declare -A extraFilesOwnership=()
declare -a nixCopyOptions=()
declare -a sshArgs=("-o" "IdentitiesOnly=yes" "-i" "$tempDir/nixos-anywhere" "-o" "UserKnownHostsFile=/dev/null" "-o" "StrictHostKeyChecking=no")

showUsage() {
  cat <<USAGE
Usage: nixos-anywhere [options] [<ssh-host>]

Options:

* -f, --flake <flake_uri>
  set the flake to install the system from. i.e.
  nixos-anywhere --flake .#mymachine
  Also supports variants:
  nixos-anywhere --flake .#nixosConfigurations.mymachine.config.virtualisation.vmVariant
* --target-host <ssh-host>
  set the SSH target host to deploy onto.
* -i <identity_file>
  selects which SSH private key file to use.
* -p, --ssh-port <ssh_port>
  set the ssh port to connect with
* --ssh-option <ssh_option>
  set one ssh option, no need for the '-o' flag, can be repeated.
  for example: '--ssh-option UserKnownHostsFile=./known_hosts'
* -L, --print-build-logs
  print full build logs
* --env-password
  set a password used by ssh-copy-id, the password should be set by
  the environment variable SSHPASS
* -s, --store-paths <disko-script> <nixos-system>
  set the store paths to the disko-script and nixos-system directly
  if this is given, flake is not needed
* --kexec <path>
  use another kexec tarball to bootstrap NixOS
* --kexec-extra-flags
  extra flags to add into the call to kexec, e.g. "--no-sync"
* --ssh-store-setting <key> <value>
  ssh store settings appended to the store URI, e.g. "compress true". <value> needs to be URI encoded.
* --post-kexec-ssh-port <ssh_port>
  after kexec is executed, use a custom ssh port to connect. Defaults to 22
* --copy-host-keys
  copy over existing /etc/ssh/ssh_host_* host keys to the installation
* --extra-files <path>
  contents of local <path> are recursively copied to the root (/) of the new NixOS installation. Existing files are overwritten
  Copied files will be owned by root unless specified by --chown option. See documentation for details.
* --chown <path> <ownership>
  change ownership of <path> recursively. Recommended to use uid:gid as opposed to username:groupname for ownership.
  Option can be specified more than once.
* --disk-encryption-keys <remote_path> <local_path>
  copy the contents of the file or pipe in local_path to remote_path in the installer environment,
  after kexec but before installation. Can be repeated.
* --no-substitute-on-destination
  disable passing --substitute-on-destination to nix-copy
  implies --no-use-machine-substituters
* --no-use-machine-substituters
  don't copy the substituters from the machine to be installed into the installer environment
* --debug
  enable debug output
* --show-trace
  show nix build traces
* --option <key> <value>
  nix option to pass to every nix related command
* --from <store-uri>
  URL of the source Nix store to copy the nixos and disko closure from
* --build-on-remote
  build the closure on the remote machine instead of locally and copy-closuring it
* --vm-test
  build the system and test the disk configuration inside a VM without installing it to the target.
* --generate-hardware-config nixos-facter|nixos-generate-config <path>
  generate a hardware-configuration.nix file using the specified backend and write it to the specified path.
  The backend can be either 'nixos-facter' or 'nixos-generate-config'.
* --phases
  comma separated list of phases to run. Default is: kexec,disko,install,reboot
  kexec: kexec into the nixos installer
  disko: first unmount and destroy all filesystems on the disks we want to format, then run the create and mount mode
  install: install the system
  reboot: unmount the filesystems, export any ZFS pools and reboot the machine
* --disko-mode disko|mount|format
  set the disko mode to format, mount or destroy. Default is disko.
  disko: first unmount and destroy all filesystems on the disks we want to format, then run the create and mount mode
* --no-disko-deps
  This will only upload the disko script and not the partitioning tools dependencies.
  Installers usually have dependencies available.
  Use this option if your target machine has not enough RAM to store the dependencies in memory.
* --build-on auto|remote|local
  sets the build on settings to auto, remote or local. Default is auto.
  auto: tries to figure out, if the build is possible on the local host, if not falls back gracefully to remote build
  local: will build on the local host
  remote: will build on the remote host
USAGE
}

abort() {
  echo "aborted: $*" >&2
  exit 1
}

step() {
  echo "### $* ###"
}

parseArgs() {
  local substituteOnDestination=y
  local printBuildLogs=n
  local buildOnRemote=n
  while [[ $# -gt 0 ]]; do
    case "$1" in
    -f | --flake)
      flake=$2
      shift
      ;;
    --target-host)
      sshConnection=$2
      shift
      ;;
    -i)
      sshPrivateKeyFile=$2
      shift
      ;;
    -p | --ssh-port)
      sshArgs+=("-p" "$2")
      shift
      ;;
    --ssh-option)
      sshArgs+=("-o" "$2")
      shift
      ;;
    -L | --print-build-logs)
      printBuildLogs=y
      ;;
    -s | --store-paths)
      diskoScript=$(readlink -f "$2")
      nixosSystem=$(readlink -f "$3")
      shift
      shift
      ;;
    --generate-hardware-config)
      if [[ $# -lt 3 ]]; then
        abort "Missing arguments for --generate-hardware-config <backend> <path>"
      fi
      case "$2" in
      nixos-facter | nixos-generate-config)
        hardwareConfigBackend=$2
        ;;
      *)
        abort "Unknown hardware config backend: $2"
        ;;
      esac
      hardwareConfigPath=$3
      shift
      shift
      ;;
    -t | --tty)
      echo "the '$1' flag is deprecated, a tty is now detected automatically" >&2
      ;;
    --help)
      showUsage
      exit 0
      ;;
    --kexec)
      kexecUrl=$2
      shift
      ;;
    --kexec-extra-flags)
      kexecExtraFlags=$2
      shift
      ;;
    --ssh-store-setting)
      key=$2
      shift
      value=$2
      shift
      sshStoreSettings+="$sshStoreSettings$key=$value&"
      shift
      ;;
    --post-kexec-ssh-port)
      postKexecSshPort=$2
      shift
      ;;
    --copy-host-keys)
      copyHostKeys=y
      ;;
    --show-trace)
      nixBuildFlags+=("--show-trace")
      ;;
    --debug)
      enableDebug="-x"
      printBuildLogs=y
      set -x
      ;;
    --disko-mode)
      case "$2" in
      format | mount | disko)
        diskoMode=$2
        ;;
      *)
        abort "Supported values for --disko-mode are disko, mount and format. Unknown mode : $2"
        ;;
      esac

      shift
      ;;
    --no-disko-deps)
      diskoDeps=n
      ;;
    --build-on)
      case "$2" in
      auto | local | remote)
        buildOn=$2
        ;;
      *)
        abort "Supported values for --build-on are auto, local and remote. Unknown mode : $2"
        ;;
      esac

      shift
      ;;
    --extra-files)
      extraFiles=$2
      shift
      ;;
    --chown)
      extraFilesOwnership["$2"]="$3"
      shift
      shift
      ;;
    --disk-encryption-keys)
      diskEncryptionKeys["$2"]="$3"
      shift
      shift
      ;;
    --phases)
      phases[kexec]=0
      phases[disko]=0
      phases[install]=0
      phases[reboot]=0
      IFS=, read -r -a phaseList <<<"$2"
      for phase in "${phaseList[@]}"; do
        if [[ ${phases[$phase]:-unset} == unset ]]; then
          abort "Unknown phase: $phase"
        fi
        phases[$phase]=1
      done
      shift
      ;;
    --stop-after-disko)
      echo "WARNING: --stop-after-disko is deprecated, use --phases kexec,disko instead" 2>&1
      phases[kexec]=1
      phases[disko]=1
      phases[install]=0
      phases[reboot]=0
      ;;
    --no-reboot)
      echo "WARNING: --no-reboot is deprecated, use --phases kexec,disko,install instead" 2>&1
      phases[kexec]=1
      phases[disko]=1
      phases[install]=1
      phases[reboot]=0
      ;;
    --from)
      nixCopyOptions+=("--from" "$2")
      shift
      ;;
    --option)
      key=$2
      shift
      value=$2
      shift
      nixOptions+=("--option" "$key" "$value")
      ;;
    --no-substitute-on-destination)
      substituteOnDestination=n
      machineSubstituters=n
      ;;
    --no-use-machine-substituters)
      machineSubstituters=n
      ;;
    --build-on-remote)
      echo "WARNING: --build-on-remote is deprecated, use --build-on remote instead" 2>&1
      buildOnRemote=y
      buildOn="remote"
      ;;
    --env-password)
      envPassword=y
      ;;
    --vm-test)
      vmTest=y
      ;;
    *)
      if [[ -z ${sshConnection} ]]; then
        sshConnection="$1"
      else
        showUsage
        exit 1
      fi
      ;;
    esac
    shift
  done

  if [[ ${diskoMode} != "" ]]; then
    if [[ ${diskoScript} != "" ]]; then
      abort "--disko-mode cannot be used if --store-paths is used"
    fi
  else
    diskoMode=disko
  fi

  diskoAttr="${diskoMode}Script"

  if [[ ${diskoDeps} == "n" ]]; then
    diskoAttr="${diskoAttr}NoDeps"
  fi

  if [[ ${printBuildLogs} == "y" ]]; then
    nixOptions+=("-L")
  fi

  if [[ $substituteOnDestination == "y" ]]; then
    nixCopyOptions+=("--substitute-on-destination")
  fi

  if [[ $vmTest == "n" ]] && [[ -z ${sshConnection} ]]; then
    abort "ssh-host must be set"
  fi

  if [[ $buildOn == "local" ]] && [[ $buildOnRemote == "y" ]]; then
    abort "Conflicting flags: --build-on local and --build-on-remote used."
  fi

  if [[ -n ${flake} ]]; then
    if [[ $flake =~ ^(.*)\#([^\#\"]*)$ ]]; then
      flake="${BASH_REMATCH[1]}"
      flakeAttr="${BASH_REMATCH[2]}"
    fi
    if [[ -z ${flakeAttr} ]]; then
      echo "Please specify the name of the NixOS configuration to be installed, as a URI fragment in the flake-uri." >&2
      echo 'For example, to use the output nixosConfigurations.foo from the flake.nix, append "#foo" to the flake-uri.' >&2
      exit 1
    fi

    # Support .#foo shorthand
    if [[ $flakeAttr != nixosConfigurations.* ]]; then
      flakeAttr="nixosConfigurations.\"$flakeAttr\".config"
    fi
  fi

}

# ssh wrapper
runSshNoTty() {
  # shellcheck disable=SC2029
  # We want to expand "$@" to get the command to run over SSH
  ssh "${sshArgs[@]}" "$sshConnection" "$@"
}
runSshTimeout() {
  timeout 10 ssh "${sshArgs[@]}" "$sshConnection" "$@"
}
runSsh() {
  # shellcheck disable=SC2029
  # We want to expand "$@" to get the command to run over SSH
  ssh "$sshTtyParam" "${sshArgs[@]}" "$sshConnection" "$@"
}

nixCopy() {
  NIX_SSHOPTS="${sshArgs[*]}" nix copy \
    "${nixOptions[@]}" \
    "${nixCopyOptions[@]}" \
    "$@"
}
nixBuild() {
  NIX_SSHOPTS="${sshArgs[*]}" nix build \
    --print-out-paths \
    --no-link \
    "${nixBuildFlags[@]}" \
    "${nixOptions[@]}" \
    "$@"
}

runVmTest() {
  if [[ -z ${flakeAttr} ]]; then
    echo "--vm-test is not supported with --store-paths" >&2
    echo "Please use --flake instead or build config.system.build.installTest of your nixos configuration manually" >&2
    exit 1
  fi

  if [[ ${buildOn} == "remote" ]]; then
    echo "--vm-test is not supported with --build-on-remote" >&2
    exit 1
  fi
  if [[ -n ${extraFiles} ]]; then
    echo "--vm-test is not supported with --extra-files" >&2
    exit 1
  fi
  if [ ${#diskEncryptionKeys[@]} -gt 0 ]; then
    echo "--vm-test is not supported with --disk-encryption-keys" >&2
    exit 1
  fi
  nix build \
    --print-out-paths \
    --no-link \
    -L \
    "${nixBuildFlags[@]}" \
    "${nixOptions[@]}" \
    "${flake}#${flakeAttr}.system.build.installTest"
}

uploadSshKey() {
  # ssh-copy-id requires this directory
  local sshCopyHome="$HOME"
  if ! mkdir -p "$HOME/.ssh/" 2>/dev/null; then
    # Fallback: create a temporary home directory for ssh-copy-id in tempDir
    sshCopyHome="$tempDir/ssh-home"
    mkdir -p "$sshCopyHome/.ssh"
    echo "Warning: Could not create $HOME/.ssh, using temporary directory: $sshCopyHome"
  fi

  if [[ -n ${sshPrivateKeyFile} ]]; then
    cp "$sshPrivateKeyFile" "$tempDir/nixos-anywhere"
    ssh-keygen -y -f "$tempDir/nixos-anywhere" >"$tempDir/nixos-anywhere.pub"
  else
    # we generate a temporary ssh keypair that we can use during nixos-anywhere
    ssh-keygen -t ed25519 -f "$tempDir"/nixos-anywhere -P "" -C "nixos-anywhere" >/dev/null
  fi

  step Uploading install SSH keys
  until
    if [[ ${envPassword} == y ]]; then
      HOME="$sshCopyHome" sshpass -e \
        ssh-copy-id \
        -o ConnectTimeout=10 \
        "${sshArgs[@]}" \
        "$sshConnection"
    else
      # To override `IdentitiesOnly=yes` set in `sshArgs` we need to set
      # `IdentitiesOnly=no` first as the first time an SSH option is
      # specified on the command line takes precedence
      HOME="$sshCopyHome" ssh-copy-id \
        -o IdentitiesOnly=no \
        -o ConnectTimeout=10 \
        "${sshArgs[@]}" \
        "$sshConnection"
    fi
  do
    sleep 3
  done
}

importFacts() {
  step Gathering machine facts
  local facts filteredFacts
  if ! facts=$(runSsh -o ConnectTimeout=10 enableDebug=$enableDebug sh -- <"$here"/get-facts.sh); then
    exit 1
  fi
  filteredFacts=$(echo "$facts" | grep -E '^(has|is)[A-Za-z0-9_]+=\S+')
  if [[ -z $filteredFacts ]]; then
    abort "Retrieving host facts via ssh failed. Check with --debug for the root cause, unless you have done so already"
  fi
  # make facts available in script
  # shellcheck disable=SC2046
  export $(echo "$filteredFacts" | xargs)

  for var in isOs isArch isKexec isInstaller isContainer hasIpv6Only hasTar hasCpio hasSudo hasDoas hasWget hasCurl hasSetsid; do
    if [[ -z ${!var} ]]; then
      abort "Failed to retrieve fact $var from host"
    fi
  done
}

checkBuildLocally() {
  local system extraPlatforms machineSystem
  system="$(nix --extra-experimental-features 'nix-command flakes' config show system)"
  extraPlatforms="$(nix --extra-experimental-features 'nix-command flakes' config show extra-platforms)"

  if [[ $# -gt 0 ]]; then
    machineSystem=$1
  elif [[ -n ${nixosSystem} ]]; then
    machineSystem="$(cat "${nixosSystem}"/system)"
  else
    machineSystem="$(nix --extra-experimental-features 'nix-command flakes' eval --raw "${flake}"#"${flakeAttr}".pkgs.system 2>/dev/null || echo "unknown")"
    if [[ ${machineSystem} == "unknown" ]]; then
      buildOn=auto
      return
    fi
  fi

  if [[ ${system} == "${machineSystem}" ]]; then
    buildOn=local
    return
  fi

  if [[ ${extraPlatforms} == "*${machineSystem}*" ]]; then
    buildOn=local
    return
  fi

  local entropy
  entropy="$(date +'%Y%m%d%H%M%S')"

  if nix build \
    -L \
    "${nixOptions[@]}" \
    --expr \
    "derivation { system = \"$machineSystem\"; name = \"env-$entropy\"; builder = \"/bin/sh\"; args = [ \"-c\" \"echo > \$out\" ]; }"; then
    # The local build failed
    buildOn=local
    return
  fi

  buildOn=remote
}

generateHardwareConfig() {
  local maybeSudo="$maybeSudo"
  mkdir -p "$(dirname "$hardwareConfigPath")"
  case "$hardwareConfigBackend" in
  nixos-facter)
    if [[ ${isInstaller} == "y" ]]; then
      maybeSudo=""
    fi
    if [[ ${hasNixOSFacter} == "n" ]]; then
      step "Generating facter.json using nixos-facter from nixpkgs"
      runSshNoTty -o ConnectTimeout=10 \
        nix run nixpkgs#nixos-facter "${nixOptions[@]}" >"$hardwareConfigPath"
    else
      step "Generating facter.json using nixos-facter"
      runSshNoTty -o ConnectTimeout=10 "${maybeSudo}" "nixos-facter" >"$hardwareConfigPath"
    fi
    ;;
  nixos-generate-config)
    step "Generating hardware-configuration.nix using nixos-generate-config"
    runSshNoTty -o ConnectTimeout=10 nixos-generate-config --show-hardware-config --no-filesystems >"$hardwareConfigPath"
    ;;
  *)
    abort "Unknown hardware config backend: $hardwareConfigBackend"
    ;;
  esac

  # to make sure nix knows about the new file
  if command -v git >/dev/null; then
    # handle relative paths
    hardwareConfigPath="$(realpath "$hardwareConfigPath")"
    pushd "$(dirname "$hardwareConfigPath")"
    if git rev-parse --is-inside-work-tree >/dev/null; then
      git add --intent-to-add --force -- "$hardwareConfigPath"
    fi
    popd
  fi
}

runKexec() {
  if [[ ${isKexec} == "y" ]] || [[ ${isInstaller} == "y" ]]; then
    return
  fi

  if [[ ${isContainer} != "none" ]]; then
    echo "WARNING: This script does not support running from a '${isContainer}' container. kexec will likely not work" >&2
  fi

  if [[ $kexecUrl == "" ]]; then
    case "${isArch}" in
    x86_64 | aarch64)
      kexecUrl="https://github.com/nix-community/nixos-images/releases/download/nixos-25.05/nixos-kexec-installer-noninteractive-${isArch}-linux.tar.gz"
      ;;
    *)
      abort "Unsupported architecture: ${isArch}. Our default kexec images only support x86_64 and aarch64 cpus. Checkout https://github.com/nix-community/nixos-anywhere/#using-your-own-kexec-image for more information."
      ;;
    esac
  fi

  step Switching system into kexec

  # no way to reach global ipv4 destinations, use gh-v6.com automatically if github url
  if [[ ${hasIpv6Only} == "y" ]] && [[ $kexecUrl == "https://github.com/"* ]]; then
    kexecUrl=${kexecUrl/"github.com"/"gh-v6.com"}
  fi

  # Define common remote commands template
  local remoteCommandTemplate
  remoteCommandTemplate="
set -eu ${enableDebug}
${maybeSudo} rm -rf /root/kexec
${maybeSudo} mkdir -p /root/kexec
%TAR_COMMAND%
TMPDIR=/root/kexec setsid --wait ${maybeSudo} /root/kexec/kexec/run --kexec-extra-flags $(printf '%q ' "$kexecExtraFlags")
"

  # Define upload commands
  local localUploadCommand=()
  local remoteUploadCommand=()

  if [[ -f $kexecUrl ]]; then
    localUploadCommand=(cat "$kexecUrl")
  elif [[ $hasWget == "y" ]]; then
    remoteUploadCommand=(wget "$kexecUrl" -O-)
  elif [[ $hasCurl == "y" ]]; then
    remoteUploadCommand=(curl --fail -Ss -L "$kexecUrl")
  else
    # Fallback to local curl
    localUploadCommand=(curl --fail -Ss -L "${kexecUrl}")
  fi

  local tarCommand
  local remoteCommands
  if [[ ${#localUploadCommand[@]} -eq 0 ]]; then
    # Use remote command for download and execution
    tarCommand="$(printf '%q ' "${remoteUploadCommand[@]}") | ${maybeSudo} tar -C /root/kexec -xvzf-"

    remoteCommands=${remoteCommandTemplate//'%TAR_COMMAND%'/$tarCommand}

    runSsh sh -c "$(printf '%q' "$remoteCommands")"
  else
    # Use local command with pipe to remote
    tarCommand="${maybeSudo} tar -C /root/kexec -xvzf-"
    remoteCommands=${remoteCommandTemplate//'%TAR_COMMAND%'/$tarCommand}

    "${localUploadCommand[@]}" | runSsh sh -c "$(printf '%q' "$remoteCommands")"
  fi

  # use the default SSH port to connect at this point
  local i
  for i in "${!sshArgs[@]}"; do
    if [[ ${sshArgs[i]} == "-p" ]]; then
      sshArgs[i + 1]=$postKexecSshPort
      break
    fi
  done

  # wait for machine to become unreachable.
  while runSshTimeout -- exit 0; do sleep 1; done

  # After kexec we explicitly set the user to root@
  sshConnection="root@${sshHost}"

  # waiting for machine to become available again
  until runSsh -o ConnectTimeout=10 -- exit 0; do sleep 5; done
}

runDisko() {
  local diskoScript=$1
  for path in "${!diskEncryptionKeys[@]}"; do
    step "Uploading ${diskEncryptionKeys[$path]} to $path"
    runSsh "umask 077; mkdir -p \"$(dirname "$path")\"; cat > $path" <"${diskEncryptionKeys[$path]}"
  done
  if [[ -n ${diskoScript} ]]; then
    nixCopy --to "ssh://$sshConnection?$sshStoreSettings" "$diskoScript"
  elif [[ ${buildOn} == "remote" ]]; then
    step Building disko script
    diskoScript=$(
      nixBuild "${flake}#${flakeAttr}.system.build.${diskoAttr}" \
        --eval-store auto --store "ssh-ng://$sshConnection?ssh-key=$tempDir%2Fnixos-anywhere&$sshStoreSettings"
    )
  fi

  step Formatting hard drive with disko
  runSsh "$diskoScript"
}

nixosInstall() {
  local nixosSystem=$1
  if [[ -n ${nixosSystem} ]]; then
    step Uploading the system closure
    nixCopy --to "ssh://$sshConnection?remote-store=local%3Froot=%2Fmnt&$sshStoreSettings" "$nixosSystem"
  elif [[ ${buildOn} == "remote" ]]; then
    step Building the system closure
    nixosSystem=$(
      nixBuild "${flake}#${flakeAttr}.system.build.toplevel" \
        --eval-store auto --store "ssh-ng://$sshConnection?ssh-key=$tempDir%2Fnixos-anywhere&remote-store=local%3Froot=%2Fmnt&$sshStoreSettings"
    )
  fi

  if [[ -n ${extraFiles} ]]; then
    step Copying extra files
    tar -C "$extraFiles" -cpf- . | runSsh "tar -C /mnt -xf- --no-same-owner"

    runSsh "chmod 755 /mnt" # tar also changes permissions of /mnt
  fi

  if [[ ${#extraFilesOwnership[@]} -gt 0 ]]; then
    # shellcheck disable=SC2016
    printf "%s\n" "${!extraFilesOwnership[@]}" "${extraFilesOwnership[@]}" | pr -2t | runSsh 'while read file ownership; do chown -R "$ownership" "/mnt/$file"; done'
  fi

  step Installing NixOS
  runSsh sh <<SSH
set -eu ${enableDebug}
# when running not in nixos we might miss this directory, but it's needed in the nixos chroot during installation
export PATH="\$PATH:/run/current-system/sw/bin"

if [ ! -d "/mnt/tmp" ]; then
  # needed for installation if initrd-secrets are used
  mkdir -p /mnt/tmp
  chmod 777 /mnt/tmp
fi

if [ ${copyHostKeys-n} = "y" ]; then
  # NB we copy host keys that are in turn copied by kexec installer.
  mkdir -m 755 -p /mnt/etc/ssh
  for p in /etc/ssh/ssh_host_*; do
    # Skip if the source file does not exist (i.e. glob did not match any files)
    # or the destination already exists (e.g. copied with --extra-files).
    if [ ! -e "\$p" ] || [ -e "/mnt/\$p" ]; then
      continue
    fi
    cp -a "\$p" "/mnt/\$p"
  done
fi
# https://stackoverflow.com/a/13864829
if [ ! -z ${NIXOS_NO_CHECK+0} ]; then
  export NIXOS_NO_CHECK
fi
nixos-install --no-root-passwd --no-channel-copy --system "$nixosSystem"
SSH

}

nixosReboot() {
  step Rebooting
  runSsh sh <<SSH
  if command -v zpool >/dev/null && [ "\$(zpool list)" != "no pools available" ]; then
    # we always want to export the zfs pools so people can boot from it without force import
    umount -Rv /mnt/
    swapoff -a
    zpool export -a || true
  fi
  nohup sh -c 'sleep 6 && reboot' >/dev/null &
SSH

  step Waiting for the machine to become unreachable due to reboot
  while runSshTimeout -- exit 0; do sleep 1; done
}

main() {
  parseArgs "$@"

  if [[ ${vmTest} == y ]]; then
    if [[ ${hardwareConfigBackend} != "none" ]]; then
      abort "--vm-test is not supported with --generate-hardware-config. You need to generate the hardware configuration before you can run the VM test." >&2
    fi
    runVmTest
    exit 0
  fi

  if [[ ${buildOn} == "auto" ]]; then
    checkBuildLocally
  fi

  # parse flake nixos-install style syntax, get the system attr
  if [[ -n ${flake} ]]; then
    if [[ ${buildOn} == "local" ]] && [[ ${hardwareConfigBackend} == "none" ]]; then
      if [[ ${phases[disko]} == 1 ]]; then
        diskoScript=$(nixBuild "${flake}#${flakeAttr}.system.build.${diskoAttr}")
      fi
      if [[ ${phases[install]} == 1 ]]; then
        nixosSystem=$(nixBuild "${flake}#${flakeAttr}.system.build.toplevel")
      fi
    fi
  elif [[ -n ${diskoScript} ]] && [[ -n ${nixosSystem} ]]; then
    if [[ ! -e ${diskoScript} ]] || [[ ! -e ${nixosSystem} ]]; then
      abort "${diskoScript} and ${nixosSystem} must be existing store-paths"
    fi
  else
    abort "--flake or --store-paths must be set"
  fi

  if [[ -n ${SSH_PRIVATE_KEY} ]] && [[ -z ${sshPrivateKeyFile} ]]; then
    # $tempDir is getting deleted on trap EXIT
    sshPrivateKeyFile="$tempDir/from-env"
    (
      umask 077
      printf '%s\n' "$SSH_PRIVATE_KEY" >"$sshPrivateKeyFile"
    )
  fi

  sshSettings=$(ssh "${sshArgs[@]}" -G "${sshConnection}")
  sshUser=$(echo "$sshSettings" | awk '/^user / { print $2 }')
  sshHost="${sshConnection//*@/}"

  uploadSshKey

  importFacts

  if [[ ${hasTar-n} == "n" ]]; then
    abort "no tar command found, but required to unpack kexec tarball"
  fi

  if [[ ${hasCpio-n} == "n" ]]; then
    abort "no cpio command found, but required to build the new initrd"
  fi

  if [[ ${hasSetsid-n} == "n" ]]; then
    abort "no setsid command found, but required to run the kexec script under a new session"
  fi

  maybeSudo=""
  if [[ ${hasSudo-n} == "y" ]]; then
    maybeSudo="sudo"
  elif [[ ${hasDoas-n} == "y" ]]; then
    maybeSudo="doas"
  fi

  if [[ ${isOs} != "Linux" ]]; then
    abort "This script requires Linux as the operating system, but got $isOs"
  fi

  if [[ ${phases[kexec]} == 1 ]]; then
    runKexec
  fi

  if [[ ${hardwareConfigBackend} != "none" ]]; then
    generateHardwareConfig
  fi

  # Before we do not have a valid hardware configuration we don't know the machine system
  if [[ ${buildOn} == "auto" ]]; then
    local remoteSystem
    remoteSystem=$(runSshNoTty -o ConnectTimeout=10 nix --extra-experimental-features nix-command config show system)
    checkBuildLocally "${remoteSystem}"
    # if we cannot figure it out at this point, we will build on the remote host
    if [[ ${buildOn} == "auto" ]]; then
      buildOn=remote
    fi
  fi

  if [[ ${buildOn} != "remote" ]] && [[ -n ${flake} ]] && [[ -z ${diskoScript} ]]; then
    if [[ ${phases[disko]} == 1 ]]; then
      diskoScript=$(nixBuild "${flake}#${flakeAttr}.system.build.${diskoAttr}")
    fi
    if [[ ${phases[install]} == 1 ]]; then
      nixosSystem=$(nixBuild "${flake}#${flakeAttr}.system.build.toplevel")
    fi
  fi

  # Installation will fail if non-root user is used for installer.
  # Switch to root user by copying authorized_keys.
  if [[ ${isInstaller} == "y" ]] && [[ ${sshUser} != "root" ]]; then
    # Allow copy to fail if authorized_keys does not exist, like if using /etc/ssh/authorized_keys.d/
    runSsh "${maybeSudo} mkdir -p /root/.ssh; ${maybeSudo} cp ~/.ssh/authorized_keys /root/.ssh || true"
    sshConnection="root@${sshHost}"
  fi

  # Get substituters from the machine and add them to the installer
  if [[ ${machineSubstituters} == "y" && -n ${flake} ]]; then
    substituters=$(nix --extra-experimental-features 'nix-command flakes' eval --apply toString "${flake}"#"${flakeAttr}".nix.settings.substituters)
    trustedPublicKeys=$(nix --extra-experimental-features 'nix-command flakes' eval --apply toString "${flake}"#"${flakeAttr}".nix.settings.trusted-public-keys)

    runSsh sh <<SSH || true
mkdir -p ~/.config/nix
echo "extra-substituters = ${substituters}" >> ~/.config/nix/nix.conf
echo "extra-trusted-public-keys = ${trustedPublicKeys}" >> ~/.config/nix/nix.conf
SSH
  fi

  if [[ ${phases[disko]} == 1 ]]; then
    runDisko "$diskoScript"
  fi

  if [[ ${phases[install]} == 1 ]]; then
    nixosInstall "$nixosSystem"
  fi

  if [[ ${phases[reboot]} == 1 ]]; then
    nixosReboot
  fi

  step "Done!"
}

main "$@"
