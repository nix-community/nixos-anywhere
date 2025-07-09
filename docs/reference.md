# Reference Manual: nixos-anywhere

**_Install NixOS everywhere via ssh_**

<img title="" src="https://raw.githubusercontent.com/nix-community/nixos-anywhere/main/docs/logo.svg" alt="" width="141">

[Documentation Index](./INDEX.md)

TODO: Populate this guide properly

## Contents

[Command Line Usage](#command-line-usage)

[Explanation of known error messages](#explanation-of-known-error-messages)

## Command Line Usage

<!-- `$ bash ./src/nixos-anywhere.sh --help` -->

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

## Explanation of known error messages

TODO: Add additional error messages and meanings. Fill in missing explanations

This section lists known error messages and their explanations. Some
explanations may refer to the following CLI syntax:

`nix run github:nix-community/nixos-anywhere -- --flake <path to configuration>#<configuration name> root@<ip address>`

This list is not comprehensive. It's possible you may encounter errors that
originate from the underlying operating system. These should be documented in
the relevant operating system manual.

| Id | Message                                                                                                                                                      | Explanation                                                                                                                                                                                                                                      |
| -- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 1  | Failure unpacking initrd                                                                                                                                     | You don't have enough RAM to hold `kexec`                                                                                                                                                                                                        |
| 2  | Flake <flake_url> does not provide attribute                                                                                                                 | The configuration name you specified in your flake URI is not defined as a NixOS configuration in your flake eg if your URI was mydir#myconfig, then myconfig should be included in the flake as `nixosConfigurations.myconfig`                  |
| 3  | Please specify the name of the NixOS configuration to be installed, as a URI fragment in the flake-uri.                                                      | As for error #2                                                                                                                                                                                                                                  |
|    | For example, to use the output nixosConfigurations.foo from the flake.nix, append "#foo" to the flake-uri                                                    |                                                                                                                                                                                                                                                  |
| 4  | Retrieving host facts via ssh failed. Check with --debug for the root cause, unless you have done so already                                                 | TODO: Explain                                                                                                                                                                                                                                    |
| 5  | ssh-host must be set                                                                                                                                         | <ip_address> has not been supplied                                                                                                                                                                                                               |
| 6  | <disko_script> and <nixos_system> must be existing store-paths                                                                                               | This occurs if the -s switch has been used to specify the disko script and store path correctly, and the scripts cannot be found at the given URI                                                                                                |
| 7  | flake must be set                                                                                                                                            | This occurs if both the -flake option (use a flake) and the -s option (specify paths directly) have been omitted. Either one or the other must be specified.                                                                                     |
| 8  | no tar command found, but required to unpack kexec tarball                                                                                                   | The destination machine does not have a `tar` command available. This is needed to unpack the `kexec`.                                                                                                                                           |
| 9  | no setsid command found, but required to run the kexec script under a new session                                                                            | The destination machine does not have the `setsid` command available                                                                                                                                                                             |
| 10 | This script requires Linux as the operating system, but got <operating system>                                                                               | The destination machine is not running Linux                                                                                                                                                                                                     |
| 11 | The default kexec image only support x86_64 cpus. Checkout https://github.com/nix-community/nixos-anywhere/#using-your-own-kexec-image for more information. | By default, `nixos-anywhere` uses its own `kexec` image, which will only run on x86_64 CPUs. For other CPU types, you can use your own `kexec` image instead. Refer to the [How To Guide](./howtos#using-your-own-kexec-image) for instructions. |
| 12 | Please specify the name of the NixOS configuration to be installed, as a URI fragment in the flake-uri.                                                      | This is a `disko` error. As for Error #2                                                                                                                                                                                                         |
|    | For example, to use the output diskoConfigurations.foo from the flake.nix, append \"#foo\" to the flake-uri.                                                 |                                                                                                                                                                                                                                                  |
| 13 | mode must be either create, mount or zap_create_mount                                                                                                        | This is a `disko` error. The `disko` switches have not been used correctly. This could happen if you supplied your own `disko` script using the -s option                                                                                        |
| 14 | disko config must be an existing file or flake must be set                                                                                                   | This is a `disko` error. This will happen if the `disko.devices` entry in your flake doesn't match the name of a file in the same location as your flake.                                                                                        |
|    |                                                                                                                                                              |                                                                                                                                                                                                                                                  |
|    |                                                                                                                                                              |                                                                                                                                                                                                                                                  |
|    |                                                                                                                                                              |                                                                                                                                                                                                                                                  |
|    |                                                                                                                                                              |                                                                                                                                                                                                                                                  |
