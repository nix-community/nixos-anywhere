# Installing on a machine with no operating system

If your machine doesn't currently have an operating system installed, you can
still run `nixos-anywhere` remotely to automate the install. To do this, you
would first need to boot the target machine from the standard NixOS installer.
You can either boot from a USB or use `netboot`.

The
[NixOS installation guide](https://nixos.org/manual/nixos/stable/index.html#sec-booting-from-usb)
has detailed instructions on how to boot the installer.

When you run `nixos-anywhere`, it will determine whether a NixOS installer is
present by checking whether the `/etc/os-release` file contains the identifier
`VARIANT_ID=installer`. This identifier is available on releases NixOS 23.05 or
later.

If an installer is detected, `nixos-anywhere` will not attempt to `kexec` into
its own image. This is particularly useful for targets that don't have enough
RAM for `kexec` or don't support `kexec`.

Often you will need some kind of network connectivity before installing NixOS.
Use the live system to connect to some network.

NixOS starts an SSH server on the installer by default, but you need to set a
password in order to access it. To set a password for the `nixos` user, run the
following command in a terminal on the NixOS machine:

```shell
passwd
```

You can then run `nixos-anywhere` like this:

```shell
nix --extra-experimental-features 'nix-command flakes' run github:nix-community/nixos-anywhere -- --flake '.#myconfig' --target-host nixos@localhost --build-on remote
```

This example assumes a flake in the current directory containing a configuration
named `myconfig`.
