# Quickstart Guide: nixos-anywhere

**_Install NixOS everywhere via ssh_**

<img src="https://raw.githubusercontent.com/numtide/nixos-anywhere/main/docs/logo.png" width="150" height="150">

[Documentation Index](./INDEX.md)

## Introduction

This guide documents a simple installation of NixOS using **nixos-anywhere** on
a target machine running x86_64 Linux with
[kexec](https://man7.org/linux/man-pages/man8/kexec.8.html) support. The example
used in this guide installs NixOS on a Hetzner cloud machine. The configuration
may be different for some other instances. We will be including further examples
in the [How To Guide](./howtos.md) as and when they are available.

You will need:

- A [flake](https://nixos.wiki/wiki/Flakes) that controls the actions to be
  performed
- A disk configuration containing details of the file system that will be
  created on the new server.

**nixos-anywhere** doesn’t need to be installed. You can run it directly from
[Numtide's repository on Github.](https://github.com/numtide/nixos-anywhere)

Details of the flake, the disk configuration and the CLI command are discussed
below.

## Steps required to run nixos-anywhere

1. Create a directory for the flake and configuration files, and ensure flakes
   are enabled on your system. The
   [Nixos Wiki](https://nixos.wiki/wiki/Flakes#enable-flakes) describes how to
   enable flakes.

2. In this directory, run the following command to create a flake.

```
nix flake init
```

This will create a flake in a file named flake.nix. Edit the flake to suit your
requirements. For a minimal installation, you can paste in the contents of the
example flake from
[here](https://github.com/numtide/nixos-anywhere-examples/blob/main/flake.nix).

Lines 29 in the sample file reads:

```
# change this to your ssh key
            "CHANGE"
```

Substitute  the text that reads `CHANGE` with your own SSH key. This is
important, otherwise you will not be able to log on to the target machine after
NixOS has been installed.

3. In the same directory, create a file named `disk-config.nix`. This will be
   used to specify the disk layout to the **disko** tool, which nixos-anywhere
   uses to partition, format and mount the disks. Again, for a simple
   installation you can paste the contents from the example
   [here](https://github.com/numtide/nixos-anywhere-examples/blob/main/disk-config.nix).
   This configures a standard GPT (GUID Partition Table) partition compatible
   with both EFI and BIOS systems, and mounts the disk as `/dev/sda`. If this
   doesn’t meet your requirements, choose an example that suits your disk layout
   from the
   [disko examples](https://github.com/nix-community/disko/tree/master/example).
   For more information about this configuration, refer to the
   [disko documentation.](https://github.com/nix-community/disko)

4. Run the following command to create the `flake.lock` file:

```
nix flake lock
```

Optionally, you can commit these files to a repo such as Github, or you can
simply reference your local directory when you run **nixos-anywhere**. This
example uses a local directory on the source machine.

5. On the target machine, make sure you have access as root via ssh by adding
   your SSH key to the file `authorized_keys` in the directory `/root/.ssh`

6. (Optional) Test your nixos and disko configuration:

The following command will automatically test your nixos configuration and run
disko inside a virtual machine, where

- `<path to configuration>` is the path to the directory or repository
  containing `flake.nix` and `disk-config.nix`

- `<configuration name>` must match the name that immediately follows the text
  `nixosConfigurations.` in the flake, as indicated by the comment in the
  [example](https://github.com/numtide/nixos-anywhere-examples/blob/main/flake.nix)).

```
nix run github:numtide/nixos-anywhere -- --flake <path to configuration>#<configuration name> --vm-test
```

7. You can now run **nixos-anywhere** from the command line as shown below,
   where:

   - `<path to configuration>` is the path to the directory or repository
     containing `flake.nix` and `disk-config.nix`

   - `<configuration name>` must match the name that immediately follows the
     text `nixosConfigurations.` in the flake, as indicated by the comment in
     the
     [example](https://github.com/numtide/nixos-anywhere-examples/blob/main/flake.nix)).

   - `<ip address>` is the IP address of the target machine.

```
nix run github:numtide/nixos-anywhere -- --flake <path to configuration>#<configuration name> root@<ip address>
```

The command would look  like this if you had created your files in a directory
named `/home/mydir/test` and the IP address of your target machine is
`37.27.18.135`:

```
nix run github:numtide/nixos-anywhere -- --flake /home/mydir/test#hetzner-cloud root@37.27.18.135
```

**nixos-anywhere** will then run, showing various output messages at each stage.
It may take some time to complete, depending on Internet speeds. It should
finish by showing the messages below before returning to the command prompt.

```
Installation finished. No error reported.
Warning: Permanently added '<ip-address>' (ED25519) to the list of known hosts
```

When this happens, the target server will have been overwritten with a new
installation of NixOS. Note that the server's public SSH key will have changed.

If you have previously accessed this server using SSH, you may see the following
message the next time you try to log in to the target.

```
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!
Someone could be eavesdropping on you right now (man-in-the-middle attack)!
It is also possible that a host key has just been changed.
The fingerprint for the ED25519 key sent by the remote host is
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.
Please contact your system administrator.
Add correct host key in ~/.ssh/known_hosts to get rid of this message.
Offending ECDSA key in ~/.ssh/known_hosts:6
  remove with:
  ssh-keygen -f ~/.ssh/known_hosts" -R "<ip addrress>"
Host key for <ip_address> has changed and you have requested strict checking.
Host key verification failed.
```

This is because the `known_hosts` file in the `.ssh` directory now contains a
mismatch, since the server has been overwritten. To solve this, use a text
editor to remove the old entry from the `known_hosts` file. The next connection
attempt will then treat this as a new server.

The error message line `Offending ECDSA key in ~/.ssh/known_hosts:` gives the
line number that needs to be removed from the `known_hosts` file.

**Note:** If you subsequently make any changes to either the `flake.nix` or
`disk-config.nix` file, you will need to run the following command in the
directory containing the flake to update `flake.lock` before rerunning
**nixos-anywhere**:

```
nix flake update
```

The new server's configurations are defined in the flake. `nixos-anywhere` does
not create `etc/nixos/configuration.nix`since it expects the server to be
administered remotely. Any future changes to the configuration should be made to
the flake, and you would reference this flake when doing the rebuild:

```
nixos-rebuild --flake <URL to your flake> switch
```

For more information on different use cases of **nixos-anywhere** please refer
to the [How to Guide](./howtos.md), and for more technical information and
explanation of known error messages, refer to the
[Reference Manual](./reference.md).
