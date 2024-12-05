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
installer's IP addresses are `10.0.2.15`, `fec0::5054:ff:fe12:3456`, and
`fe80::5054:ff:fe12:3456%eth0`:

To test if you can connect and your password works, you can use the following
SSH command (replace the IP address with your own):

```
ssh -v nixos@fec0::5054:ff:fe12:3456
```

You can then use the IP address to run `nixos-anywhere` like this:

```
nix run github:nix-community/nixos-anywhere -- --flake '.#myconfig' --target-host nixos@fec0::5054:ff:fe12:3456
```

This example assumes a flake in the current directory containing a configuration
named `myconfig`.
