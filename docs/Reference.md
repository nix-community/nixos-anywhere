# Reference Manual: nixos-anywhere

TODO: Populate this guide properly

## Contents

[Command Line Usage](developer-guide)

[Developer guide](developer-guide)

[Explanation of known error messages](explanation-of-known-error-messages)

## Command Line Usage

```
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
```

## Developer guide

To run `nixos-anywhere` from the repo:

```shell
nix run . -- --help
```

To format the code

```shell
nix fmt
```

# ## Explanation of known error messages

TODO: List actual error messages and meanings. Include:

If you do not have enough RAM you will see failures unpacking the initrd), this is because kexec needs to load the whole nixos into memory.
