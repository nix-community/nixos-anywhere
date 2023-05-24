# Reference Manual: nixos-anywhere

***Install NixOS everywhere via ssh***

<img title="" src="https://raw.githubusercontent.com/numtide/nixos-anywhere/main/docs/logo.png" alt="" width="141">

TODO: Populate this guide properly

## Contents

[Command Line Usage](#command-line-usage)

[Explanation of known error messages](#explanation-of-known-error-messages)

## Command Line Usage

<!-- `$ bash ./src/nixos-anywhere.sh --help` -->

```
Usage: nixos-anywhere [options] ssh-host

Options:

* -f, --flake <flake_uri>
  set the flake to install the system from.
* -i <identity_file>
  selects which SSH private key file to use.
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
```

## Explanation of known error messages

TODO: Add additional error messages and meanings. Fill in missing explanations

This section lists known error messages and their explanations. Some explanations may refer to the following CLI syntax:

`nix run github:numtide/nixos-anywhere -- --flake <path to configuration>#<configuration name> root@<ip address>`

| Id  | Message                                                                                                                                                                                                                   | Explanation                                                                                                                                                                                                                                      |
| --- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 1   | Failure unpacking initrd                                                                                                                                                                                                  | You don't have enough RAM to hold `kexec`                                                                                                                                                                                                        |
| 2   | Flake <flake_url> does not provide attirbute                                                                                                                                                                              | The configuration name you specified in your flake URI is not defined as a NixOS configuration in your flake eg if your URI was mydir#myconfig, then myconfig should be included in the flake as `nixosConfigurations.myconfig`                  |
| 3   | Please specify the name of the NixOS configuration to be installed, as a URI fragment in the flake-uri.                                                                                                                   | As for error #2                                                                                                                                                                                                                                  |
|     | For example, to use the output nixosConfigurations.foo from the flake.nix, append "#foo" to the flake-uri                                                                                                                 |                                                                                                                                                                                                                                                  |
| 4   | Retrieving host facts via ssh failed. Check with --debug for the root cause, unless you have done so already                                                                                                              | TODO: Explain                                                                                                                                                                                                                                    |
| 5   | ssh-host must be set                                                                                                                                                                                                      | <ip_address> has not been supplied                                                                                                                                                                                                               |
| 6   | <disko_script> and <nixos_system> must be existing store-paths                                                                                                                                                            | This occurs if the -s switch has been used to specify the disko script and store path correctly, and the scripts cannot be found at the given URI                                                                                                |
| 7   | flake must be set                                                                                                                                                                                                         | This occurs if both the -flake option (use a flake) and the -s option (specify paths directly) have been omitted. Either one or the other must be specified.                                                                                     |
| 8   | no tar command found, but required to unpack kexec tarball                                                                                                                                                                | The destination machine does not have a `tar` command available. This is needed to unpack the `kexec`.                                                                                                                                           |
| 9   | no setsid command found, but required to run the kexec script under a new session                                                                                                                                         | The destination machine does not have the `setsid` command available                                                                                                                                                                             |
| 10  | This script requires Linux as the operating system, but got <operating system>                                                                                                                                            | The destination machine is not running Linux                                                                                                                                                                                                     |
| 11  | The default kexec image only support x86_64 cpus. Checkout https://github.com/numtide/nixos-anywhere/#using-your-own-kexec-image for more information.                                                                    | By default, `nixos-anywhere` uses its own `kexec` image, which will only run on x86_64 CPUs. For other CPU types, you can use your own `kexec` image instead. Refer to the [How To Guide](./howtos#using-your-own-kexec-image) for instructions. |
| 12  | Please specify the name of the NixOS configuration to be installed, as a URI fragment in the flake-uri.<br/>For example, to use the output diskoConfigurations.foo from the flake.nix, append \"#foo\" to the flake-uri. | This is a `disko` error. As for Error #2                                                                                                                                                                                                         |
| 13  | mode must be either create, mount or zap_create_mount                                                                                                                                                                     | This is a `disko` error. The `disko` switches have not been used correctly. This could happen if you supplied your own `disko` script using the -s option                                                                                        |
| 14  | disko config must be an existing file or flake must be set                                                                                                                                                                | This is a `disko` error. This will happen if the `disko.devices` entry in your flake doesn't match the name of a file in the same location as your flake.                                                                                        |
|     |                                                                                                                                                                                                                           |                                                                                                                                                                                                                                                  |
|     |                                                                                                                                                                                                                           |                                                                                                                                                                                                                                                  |
|     |                                                                                                                                                                                                                           |                                                                                                                                                                                                                                                  |
|     |                                                                                                                                                                                                                           |                                                                                                                                                                                                                                                  |
