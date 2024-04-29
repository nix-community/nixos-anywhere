# Quickstart Guide: nixos-anywhere

**_Install NixOS everywhere via ssh_**

<img src="https://raw.githubusercontent.com/nix-community/nixos-anywhere/main/docs/logo.png" width="150" height="150">

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
- A target machine, reachable via SSH, with your SSH public key deployed and and
  the privilege to either login directly as root or to use password-less sudo.

**nixos-anywhere** doesn’t need to be installed. You can run it directly from
[Numtide's repository on Github.](https://github.com/nix-community/nixos-anywhere)

Details of the flake, the disk configuration and the CLI command are discussed
below.

## Steps required to run nixos-anywhere

1. **Enable Flakes**:

   Ensure that flakes are enabled on your system. To enable flakes, refer to the
   [NixOS Wiki](https://wiki.nixos.org/wiki/Flakes#enable-flakes).

2. **Initialize a Flake**:

   The easiest way to start is to copy our
   [example flake.nix](https://github.com/nix-community/nixos-anywhere-examples/blob/main/flake.nix)
   into a new directory. This example is tailored for a virtual machine setup
   similar to one on [Hetzner Cloud](https://www.hetzner.com/cloud), so you
   might need to adapt it for your setup.

   **Hardware-Specific Configuration**: If you're not using a virtual machine,
   you'll need to generate a custom hardware configuration with
   `nixos-generate-config`.

- **Get `nixos-generate-config` onto the Target Machine**:

  1. **Option 1**: If NixOS is not installed, boot into an installer without
     first installing NixOS.
  2. **Option 2**: Use the kexec tarball method, as described
     [here](https://github.com/nix-community/nixos-images#kexec-tarballs).

- **Generate Configuration**: Run the following command on the target machine:

  ```bash
  nixos-generate-config --no-filesystems --root /mnt
  ```

  This creates the necessary configuration files under `/mnt/etc/nixos/`, which
  you can then customize as needed and copy them to your local machine in order
  to include them in your flake.

3. **Find SSH Key Line**:\
   if you cloned
   [our nixos-anywhere-example](https://github.com/nix-community/nixos-anywhere-examples/blob/main/configuration.nix)
   you will also replace the SSH key like this: In your configuration, locate
   the line that reads:

   ```bash
   # change this to your ssh key
               "CHANGE"
   ```

   Replace the text `CHANGE` with your own SSH key. This is crucial, as you will
   not be able to log into the target machine post-installation without it.

4. In the same directory, create a file named `disk-config.nix`. This will be
   used to specify the disk layout to the **disko** tool, which nixos-anywhere
   uses to partition, format and mount the disks. Again, for a simple
   installation you can paste the contents from the example
   [here](https://github.com/nix-community/nixos-anywhere-examples/blob/main/disk-config.nix).
   This configures a standard GPT (GUID Partition Table) partition compatible
   with both EFI and BIOS systems, and mounts the disk as `/dev/sda`. If this
   doesn’t meet your requirements, choose an example that suits your disk layout
   from the
   [disko examples](https://github.com/nix-community/disko/tree/master/example).
   For more information about this configuration, refer to the
   [disko documentation.](https://github.com/nix-community/disko)

5. Run the following command to create the `flake.lock` file:

   ```
   nix flake lock
   ```

   Optionally, you can commit these files to a repo such as Github, or you can
   simply reference your local directory when you run **nixos-anywhere**. This
   example uses a local directory on the source machine.

6. On the target machine, make sure you have access as root via ssh by adding
   your SSH key to the file `authorized_keys` in the directory `/root/.ssh`

   Optionally, bootstrapping can also be performed through password login. For
   example through the `image-installer-*` provided by
   `nix-community/nixos-images`. Assign your password to the `SSH_PASS`
   environment variable and specify `--env-password` as an additional command
   line option. This will provide `ssh-copy-id` with the required password.

7. (Optional) Test your nixos and disko configuration:

   The following command will automatically test your nixos configuration and
   run disko inside a virtual machine, where

   - `<path to configuration>` is the path to the directory or repository
     containing `flake.nix` and `disk-config.nix`

   - `<configuration name>` must match the name that immediately follows the
     text `nixosConfigurations.` in the flake, as indicated by the comment in
     the
     [example](https://github.com/nix-community/nixos-anywhere-examples/blob/main/flake.nix)).

   ```
   nix run github:nix-community/nixos-anywhere -- --flake <path to configuration>#<configuration name> --vm-test
   ```

8. You can now run **nixos-anywhere** from the command line as shown below,
   where:

   - `<path to configuration>` is the path to the directory or repository
     containing `flake.nix` and `disk-config.nix`

   - `<configuration name>` must match the name that immediately follows the
     text `nixosConfigurations.` in the flake, as indicated by the comment in
     the
     [example](https://github.com/nix-community/nixos-anywhere-examples/blob/main/flake.nix)).

   - `<ip address>` is the IP address of the target machine.

     ```
     nix run github:nix-community/nixos-anywhere -- --flake <path to configuration>#<configuration name> root@<ip address>
     ```

     The command would look  like this if you had created your files in a
     directory named `/home/mydir/test` and the IP address of your target
     machine is `37.27.18.135`:

     ```
     nix run github:nix-community/nixos-anywhere -- --flake /home/mydir/test#hetzner-cloud root@37.27.18.135
     ```

     **nixos-anywhere** will then run, showing various output messages at each
     stage. It may take some time to complete, depending on Internet speeds. It
     should finish by showing the messages below before returning to the command
     prompt.

     ```
     Installation finished. No error reported.
     Warning: Permanently added '<ip-address>' (ED25519) to the list of known hosts
     ```

     When this happens, the target server will have been overwritten with a new
     installation of NixOS. Note that the server's public SSH key will have
     changed.

     If you have previously accessed this server using SSH, you may see the
     following message the next time you try to log in to the target.

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

     This is because the `known_hosts` file in the `.ssh` directory now contains
     a mismatch, since the server has been overwritten. To solve this, use a
     text editor to remove the old entry from the `known_hosts` file. The next
     connection attempt will then treat this as a new server.

     The error message line `Offending ECDSA key in ~/.ssh/known_hosts:` gives
     the line number that needs to be removed from the `known_hosts` file.

     The new server's configurations are defined in the flake. `nixos-anywhere`
     does not create `etc/nixos/configuration.nix`, since it expects the server
     to be administered remotely. Any future changes to the configuration should
     be made to the flake, and you would reference this flake when doing the
     nixos-rebuild command or a deployment tool of your choice i.e.
     [colmena](https://github.com/zhaofengli/colmena),
     [nixinate](https://github.com/MatthewCroughan/nixinate).

     This example can be run from the machine itself for updating (replace
     `<URL to your flake>` with your flake i.e. `.#` if your flake is in the
     current directory):

     ```
     nixos-rebuild switch --flake <URL to your flake>
     ```

     You can also run `nixos-rebuild` to update a machine remotely, if you have
     set up an openssh server and your ssh key for the root user:

     ```
     nixos-rebuild switch --flake <URL to your flake> --target-host "root@<ip address>"
     ```

     For more information on different use cases of **nixos-anywhere** please
     refer to the [How to Guide](./howtos/INDEX.md), and for more technical
     information and explanation of known error messages, refer to the
     [Reference Manual](./reference.md).
