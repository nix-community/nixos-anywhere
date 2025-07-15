# Quickstart Guide: nixos-anywhere

**_Install NixOS everywhere via ssh_**

<img src="https://raw.githubusercontent.com/nix-community/nixos-anywhere/main/docs/logo.svg" width="150" height="150">

[Documentation Index](./INDEX.md)

## Introduction

This guide documents a simple installation of NixOS using **nixos-anywhere** on
a target machine running x86_64 Linux with
[kexec](https://man7.org/linux/man-pages/man8/kexec.8.html) support. The example
used in this guide installs NixOS on a Hetzner cloud machine. The configuration
may be different for some other instances. We will be including further examples
in the [How To Guide](./howtos/INDEX.md) as and when they are available.

You will need:

- A [flake](https://wiki.nixos.org/wiki/Flakes) that controls the actions to be
  performed
- A disk configuration containing details of the file system that will be
  created on the new server.
- A target machine that is reachable via SSH, either using keys or a password,
  and the privilege to either log in directly as root or a user with
  password-less sudo.

**nixos-anywhere** doesn’t need to be installed. You can run it directly from
[the Github repository.](https://github.com/nix-community/nixos-anywhere)

Details of the flake, the disk configuration and the CLI command are discussed
below.

## Steps required to run nixos-anywhere

### 1. Enable Flakes

Check if your nix has flakes enabled by running `nix flake`. It will tell you if
it's not. To enable flakes, refer to the
[NixOS Wiki](https://wiki.nixos.org/wiki/Flakes#enable-flakes).

### 2. Initialize a Flake

The easiest way to start is to copy our
[example flake.nix](https://github.com/nix-community/nixos-anywhere-examples/blob/main/flake.nix)
into a new directory. This example is tailored for a virtual machine setup
similar to one on [Hetzner Cloud](https://www.hetzner.com/cloud), so you might
need to adapt it for your setup.

If you already have a flake, you can use it by adding
[disko configuration](https://github.com/nix-community/disko?tab=readme-ov-file#how-to-use-disko)
to it.

### 3. Configure your SSH key

If you cloned
[our nixos-anywhere-example](https://github.com/nix-community/nixos-anywhere-examples/blob/main/configuration.nix)
you will also replace the SSH key like this: In your configuration, locate the
line that reads:

```bash
# change this to your ssh key
            "CHANGE"
```

Replace the text `CHANGE` with your own SSH key. This is crucial, as you will
not be able to log into the target machine post-installation without it. If you
have a .pem file you can run

```bash
ssh-keygen -y -f /path/to/your/key.pem
```

then paste the result in between the quotes like "ssh-rsa AAA..."

### 4. Configure Storage

In the same directory, create a file called `disk-config.nix`. This file will
define the disk layout for the
[disko](https://github.com/nix-community/disko/blob/master/docs/INDEX.md) tool,
which is used by nixos-anywhere to partition, format, and mount the disks.

For a basic installation, you can copy the contents from the example provided
[here](https://github.com/nix-community/nixos-anywhere-examples/blob/main/disk-config.nix).
This configuration sets up a standard GPT (GUID Partition Table) that is
compatible with both EFI and BIOS systems and mounts the disk as `/dev/sda`. You
may need to adjust `/dev/sda` to match the correct disk on your machine. To
identify the disk, run the `lsblk` command and replace `sda` with the actual
disk name.

For example, on this machine, we would select `/dev/nvme0n1` as the disk:

```
NAME        MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
nvme0n1     259:0    0  1.8T  0 disk
```

If this setup does not match your requirements, you can choose an example that
better suits your disk layout from the
[disko examples](https://github.com/nix-community/disko/tree/master/example).
For more detailed information, refer to the
[disko documentation](https://github.com/nix-community/disko).

### 5. Lock your Flake

```
nix flake lock
```

This will download your flake dependencies and make a `flake.lock` file that
describes how to reproducibly build your system.

Optionally, you can commit these files to a repo such as Github, or you can
simply reference your local directory when you run **nixos-anywhere**. This
example uses a local directory on the source machine.

### 6. Connectivity to the Target Machine

**nixos-anywhere** will create a temporary SSH key to use for the installation.
If your SSH key is not found, you will be asked for your password. If you are
using a non-root user, you must have access to sudo without a password. To avoid
SSH password prompts, set the `SSHPASS` environment variable to your password
and add `--env-password` to the `nixos-anywhere` command. If providing a
specific SSH key through `-i` (identity_file), this key will then be used for
the installation and no temporary SSH key will be created.

### 7. (Optional) Test your NixOS and Disko configuration

Skip this step and continue with Step 8, if you don't have a hardware
configuration (hardware-configuration.nix or facter.json) generated yet or make
sure you don't import non-existing hardware-configuration.nix or facter.json
during running the vm test.

The following command will automatically test your nixos configuration and run
disko inside a virtual machine, where

- `<path to configuration>` is the path to the directory or repository
  containing `flake.nix` and `disk-config.nix`

- `<configuration name>` must match the name that immediately follows the text
  `nixosConfigurations.` in the flake, as indicated by the comment in the
  [example](https://github.com/nix-community/nixos-anywhere-examples/blob/main/flake.nix).

```
nix run github:nix-community/nixos-anywhere -- --flake <path to configuration>#<configuration name> --vm-test
```

### 8. Prepare Hardware Configuration

If you're not using a virtual machine, it's recommended to allow
`nixos-anywhere` to generate a hardware configuration during installation. This
ensures that essential drivers, such as those required for disk detection, are
properly configured.

To enable `nixos-anywhere` to integrate its generated configuration into your
NixOS setup, you need to include an import for the hardware configuration
beforehand.

Here’s an example:

```diff
 nixosConfigurations.generic = nixpkgs.lib.nixosSystem {
   system = "x86_64-linux";
   modules = [
     disko.nixosModules.disko
     ./configuration.nix
+    ./hardware-configuration.nix
   ];
 };
```

When running `nixos-anywhere`, this file is automatically generated by including
the following flags in your command:
`--generate-hardware-config nixos-generate-config ./hardware-configuration.nix`.
The second flag, `./hardware-configuration.nix`, specifies where
`nixos-generate-config` will store the configuration. Adjust this path to
reflect the location where you want the `hardware-configuration.nix` for this
machine to be saved.

#### 8.1 nixos-facter

As an alternative to `nixos-generate-config`, you can use the experimental
[nixos-facter](https://github.com/numtide/nixos-facter) command, which offers
more comprehensive hardware reports and advanced configuration options.

To use `nixos-facter`, add the following to your flake inputs:

```diff
 {
+ inputs.nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
 }
```

Next, import the module into your configuration and specify `facter.json` as the
path where the hardware report will be saved:

```diff
 nixosConfigurations.generic-nixos-facter = nixpkgs.lib.nixosSystem {
   system = "x86_64-linux";
   modules = [
     disko.nixosModules.disko
     ./configuration.nix
+    nixos-facter-modules.nixosModules.facter
+    { config.facter.reportPath = ./facter.json }
   ];
 };
```

To generate the configuration for `nixos-facter` with `nixos-anywhere`, use the
following flags: `--generate-hardware-config nixos-facter ./facter.json`. The
second flag, `./facter.json`, specifies where `nixos-generate-config` will store
the hardware report. Adjust this path to suit the location where you want the
`facter.json` to be saved.

### 9. Run it

You can now run **nixos-anywhere** from the command line as shown below, where:

- `<path to configuration>` is the path to the directory or repository
  containing `flake.nix` and `disk-config.nix`

- `<configuration name>` must match the name that immediately follows the text
  `nixosConfigurations.` in the flake, as indicated by the comment in the
  [example](https://github.com/nix-community/nixos-anywhere-examples/blob/main/flake.nix).

- `<ip address>` is the IP address of the target machine.

```
nix run github:nix-community/nixos-anywhere -- --flake <path to configuration>#<configuration name> --target-host root@<ip address>
```

The command would look  like this if you had created your files in a directory
named `/home/mydir/test` and the IP address of your target machine is
`37.27.18.135`:

```
nix run github:nix-community/nixos-anywhere -- --flake /home/mydir/test#hetzner-cloud --target-host root@37.27.18.135
```

If you also need to generate hardware configuration amend flags for
nixos-generate-config:

```
nix run github:nix-community/nixos-anywhere -- --generate-hardware-config nixos-generate-config ./hardware-configuration.nix --flake <path to configuration>#<configuration name> --target-host root@<ip address>
```

Or these flags if you are using nixos-facter instead:

```
nix run github:nix-community/nixos-anywhere -- --generate-hardware-config nixos-facter ./facter.json  --flake <path to configuration>#<configuration name> --target-host root@<ip address>
```

Adjust the location of `./hardware-configuration.nix` and `./facter.json`
accordingly.

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
  ssh-keygen -f ~/.ssh/known_hosts" -R "<ip address>"
Host key for <ip_address> has changed and you have requested strict checking.
Host key verification failed.
```

This is because the `known_hosts` file in the `.ssh` directory now contains a
mismatch, since the server has been overwritten. To solve this, use a text
editor to remove the old entry from the `known_hosts` file (or use the command
`ssh-keygen -R <ip_address>`). The next connection attempt will then treat this
as a new server.

The error message line `Offending ECDSA key in ~/.ssh/known_hosts:6` gives the
line number that needs to be removed from the `known_hosts` file (line 6 in this
example).

# Finished!

**nixos-anywhere**'s job is now done, as it is a tool to install NixOS onto the
target machine.

Any future changes to the configuration should be made to your flake. You would
reference this flake when using the NixOS `nixos-rebuild` command or a separate
3rd party deployment tool of your choice i.e.
[deploy-rs](https://github.com/serokell/deploy-rs),
[colmena](https://github.com/zhaofengli/colmena),
[nixinate](https://github.com/MatthewCroughan/nixinate),
[clan](https://clan.lol/) (author's choice).

To update on the machine locally (replace `<URL to your flake>` with your flake
i.e. `.#` if your flake is in the current directory):

```
nixos-rebuild switch --flake <URL to your flake>
```

To update remotely you will need to have configured an
[ssh server](https://search.nixos.org/options?show=services.sshd.enable) and
your ssh key for the
[root user](https://search.nixos.org/options?show=users.users.%3Cname%3E.openssh.authorizedKeys.keys):

```
nixos-rebuild switch --flake <URL to your flake> --target-host "root@<ip address>"
```

See the Nix documentation for use of the flake
[URL-like syntax](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake#url-like-syntax).

For more information on different use cases of **nixos-anywhere** please refer
to the [How to Guide](./howtos/INDEX.md), and for more technical information and
explanation of known error messages, refer to the
[Reference Manual](./reference.md).
