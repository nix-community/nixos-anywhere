# CLI

```
Usage: nixos-anywhere [options] [<ssh-host>]

Options:

* -f, --flake <flake_uri>
  set the flake to install the system from.
* --target-host <ssh-host>
  specified the SSH target host to deploy onto.
* -i <identity_file>
  selects which SSH private key file to use.
* -p, --ssh-port <ssh_port>
  set the ssh port to connect with
* --ssh-option <ssh_option>
  set an ssh option
* -L, --print-build-logs
  print full build logs
* --env-password
  set a password used by ssh-copy-id, the password should be set by
  the environment variable SSHPASS
* -s, --store-paths <disko-script> <nixos-system>
  set the store paths to the disko-script and nixos-system directly
  if this is given, flake is not needed
* --no-reboot
  do not reboot after installation, allowing further customization of the target installation.
* --kexec <path>
  use another kexec tarball to bootstrap NixOS
* --kexec-extra-flags
  extra flags to add into the call to kexec, e.g. "--no-sync"
* --ssh-store-settings
  extra ssh store settings appended to the store URI e.g. "compress=true&max-connections=10"
* --post-kexec-ssh-port <ssh_port>
  after kexec is executed, use a custom ssh port to connect. Defaults to 22
* --copy-host-keys
  copy over existing /etc/ssh/ssh_host_* host keys to the installation
* --stop-after-disko
  exit after disko formatting, you can then proceed to install manually or some other way
* --extra-files <path>
  contents of local <path> are recursively copied to the root (/) of the new NixOS installation. Existing files are overwritten
  Copied files will be owned by root. See documentation for details.
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
* --build-on auto|remote|local
  sets the build on settings to auto, remote or local. Default is auto.
  auto: tries to figure out, if the build is possible on the local host, if not falls back gracefully to remote build
  local: will build on the local host
  remote: will build on the remote host
```
