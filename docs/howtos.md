# How To Guide: nixos-anywhere

## Contents

[Installing on a machine with no operating system](#installing-on-a-machine-with-no-operating-system)

[Using your own kexec image](#using-your-own-kexec-image)

[Using nixos-anywhere without flakes](#using-nixos-anywhere-without-flakes)

## Installing on a machine with no operating system

If your machine does not run any operating system, you can boot the standard
NixOS installer using a USB or netboot. Detailed instructions on how to do this
can be found in the
[NixOS installation guide](https://nixos.org/manual/nixos/stable/index.html#sec-booting-from-usb).

When you're using `nixos-anywhere`, it will detect a NixOS installer by checking
if the `/etc/os-release` file contains the identifier `VARIANT=installer`
(available since NixOS 23.05). If an installer is detected, `nixos-anywhere`
will not attempt to kexec into its own image. This is particularly useful for
targets that do not have enough RAM for kexec or do not support kexec.

NixOS starts an SSH server on the installer by default, but you need to set a
password in order to access it. To set a password for the `nixos` user, run the
following command in a terminal on the NixOS machine:

```
passwd
```

If you don't know the IP address of the installer on your network, you can find
it by running the following command:

```
$ ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:12:34:56 brd ff:ff:ff:ff:ff:ff
    altname enp0s3
    altname ens3
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic noprefixroute eth0
       valid_lft 86385sec preferred_lft 75585sec
    inet6 fec0::5054:ff:fe12:3456/64 scope site dynamic mngtmpaddr noprefixroute
       valid_lft 86385sec preferred_lft 14385sec
    inet6 fe80::5054:ff:fe12:3456/64 scope link
       valid_lft forever preferred_lft forever
```

This will display the IP addresses assigned to your network interface(s),
including the IP address of the installer. In the example output below, the
installer's IP address is `10.0.2.15`, `fec0::5054:ff:fe12:3456`, and
`fe80::5054:ff:fe12:3456%eth0`:

To test if you can connect and your password works, you can use the following
SSH command (replace the IP address with your own):

```
ssh -v nixos@fec0::5054:ff:fe12:3456
```

You can then use the IP address and other parameters in nixos-anywhere, like
this:

```
nixos-anywhere --flake '.#' nixos@fec0::5054:ff:fe12:3456
```

## Using your own kexec image

By default, nixos-anywhere downloads the kexec image from the off
[NixOS images repository](https://github.com/nix-community/nixos-images#kexec-tarballs).
However, you can provide your own kexec image file if desired. To do this, use
the `--kexec` command line switch followed by the path to your image file. The
image will be uploaded prior to execution.

Here's an example command that demonstrates how to use a custom kexec image with
`nixos-anywhere` for aarch64 instead of the default `x86_64` architecture:

```
nixos-anywhere \
  --kexec "$(nix build --print-out-paths github:nix-community/nixos-images#packages.aarch64-linux.kexec-installer-noninteractive-nixos-unstable)/nixos-kexec-installer-noninteractive-aarch64-linux.tar.gz" \
  --flake 'github:your-user/your-repo#your-system' \
  root@yourip
```

Make sure to replace `github:your-user/your-repo#your-system` with the
appropriate Flake URL representing your NixOS configuration.

This is particularly useful for architectures other than `x86_64`, where there
is no pre-build image.

The example above assumes that your local machine can build for aarch64 either
natively, through a remote builder or by emulating the architecture with qemu
with the following NixOS configuration:

```nix
{
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
}
```
