# CLI

```
Usage: nixos-anywhere [options] ssh-host

Options:

* -f, --flake flake
  set the flake to install the system from
* -s, --store-paths
  set the store paths to the disko-script and nixos-system directly
  if this is give, flake is not needed
* --kexec url
  use another kexec tarball to bootstrap NixOS
* --debug
  enable debug output

```
