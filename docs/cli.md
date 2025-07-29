# CLI

<!-- `$ nix run . -- --help` -->

```
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
```
