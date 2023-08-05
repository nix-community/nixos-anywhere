# How To Guide: nixos-anywhere

**_Install NixOS everywhere via ssh_**

<img title="" src="https://raw.githubusercontent.com/numtide/nixos-anywhere/main/docs/logo.png" alt="" width="129">

[Documentation Index](./INDEX.md)

## Contents

[Installing on a machine with no operating system](#installing-on-a-machine-with-no-operating-system)

[Using your own kexec image](#using-your-own-kexec-image)

[Secrets and full disk encryption](#secrets-and-full-disk-encryption)

## Installing on a machine with no operating system

If your machine doesn't currently have an operating system installed, you can
still run `nixos-anywhere` remotely to automate the install. To do this, you
would first need to boot the target machine from the standard NixOS installer.
You can either boot from a USB or use `netboot`.

The
[NixOS installation guide](https://nixos.org/manual/nixos/stable/index.html#sec-booting-from-usb)
has detailed instructions on how to boot the installer.

When you run `nixos-anywhere`, it will determine whether a NixOS installer is
present by checking whether the `/etc/os-release` file contains the identifier
`VARIANT=installer`. This identifier is available on releases NixOS 23.05 or
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
nix run github:numtide/nixos-anywhere -- --flake '.#myconfig' nixos@fec0::5054:ff:fe12:3456
```

This example assumes a flake in the curent directory containing a configuration
named `myconfig`.

## Using your own kexec image

By default, `nixos-anywhere` downloads the kexec image from the
[NixOS images repository](https://github.com/nix-community/nixos-images#kexec-tarballs).

However, you can provide your own `kexec` image file if you need to use a
different one. This is particularly useful for architectures other than `x86_64`
and `aarch64`, since they don't have a pre-build image.

To do this, use the `--kexec` command line switch followed by the path to your
image file. The image will be uploaded prior to execution.

Here's an example command that demonstrates how to use a custom kexec image with
`nixos-anywhere`:

```
nix run github:numtide/nixos-anywhere -- \
  --kexec "$(nix build --print-out-paths github:nix-community/nixos-images#packages.aarch64-linux.kexec-installer-nixos-unstable-noninteractive)/nixos-kexec-installer-noninteractive-aarch64-linux.tar.gz" \
  --flake 'github:your-user/your-repo#your-system' \
  root@yourip
```

Make sure to replace `github:your-user/your-repo#your-system` with the
appropriate Flake URL representing your NixOS configuration.

The example above assumes that your local machine can build for aarch64 in one
of the following ways:

- Natively

- Through a remote builder

- By emulating the architecture with qemu using the following NixOS
  configuration:

```nix
{
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
}
```

## Secrets and full disk encryption

The `nixos-anywhere` utility offers the capability to install secrets onto a
target machine. This feature is particularly beneficial when you want to
bootstrap secrets management tools such as
[sops-nix](https://github.com/Mic92/sops-nix) or
[agenix](https://github.com/ryantm/agenix), which rely on machine-specific
secrets to decrypt other uploaded secrets.

### Example: Decrypting an OpenSSH Host Key with pass

In this example, we demonstrate how to use a script to decrypt an OpenSSH host
key from the `pass` password manager and subsequently pass it to
`nixos-anywhere` during the installation process:

```bash
#!/usr/bin/env bash

# Create a temporary directory
temp=$(mktemp -d)

# Function to cleanup temporary directory on exit
cleanup() {
  rm -rf "$temp"
}
trap cleanup EXIT

# Create the directory where sshd expects to find the host keys
install -d -m755 "$temp/etc/ssh"

# Decrypt your private key from the password store and copy it to the temporary directory
pass ssh_host_ed25519_key > "$temp/etc/ssh/ssh_host_ed25519_key"

# Set the correct permissions so sshd will accept the key
chmod 600 "$temp/etc/ssh/ssh_host_ed25519_key"

# Install NixOS to the host system with our secrets
nixos-anywhere --extra-files "$temp" --flake '.#your-host' root@yourip
```

### Example: Uploading Disk Encryption Secrets

In a similar vein, `nixos-anywhere` can upload disk encryption secrets, which
are necessary during formatting with disko. Here's an example that demonstrates
how to provide your disk encryption password as a file or via the `pass` utility
to `nixos-anywhere`:

```bash
# Write your disk encryption password to a file
echo "my-super-safe-password" > /tmp/disk-1.key

# Call nixos-anywhere with disk encryption keys
nixos-anywhere \
  --disk-encryption-keys /tmp/disk-1.key /tmp/disk-1.key \
  --disk-encryption-keys /tmp/disk-2.key <(pass my-disk-encryption-password) \
  --flake '.#your-host' \
  root@yourip
```

In the above example, replace `"my-super-safe-password"` with your actual
encryption password, and `my-disk-encryption-password` with the relevant entry
in your pass password store. Also, ensure to replace `'.#your-host'` and
`root@yourip` with your actual flake and IP address, respectively.
