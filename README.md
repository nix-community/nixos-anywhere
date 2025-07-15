# nixos-anywhere

**_Install NixOS everywhere via ssh_**

<img src="https://raw.githubusercontent.com/nix-community/nixos-anywhere/main/docs/logo.svg" width="150" height="150">

[Documentation Index](docs/INDEX.md)

## README

Setting up a new machine is time-consuming, and becomes complicated when it
needs to be done remotely. If you're installing NixOS, the **nixos-anywhere**
tool allows you to pre-configure the whole process including:

- Disk partitioning and formatting
- Configuring and installing NixOS
- Installing additional files and software

You can then initiate an unattended installation with a single CLI command.
Since **nixos-anywhere** can access the new machine using SSH, it's ideal for
remote installations.

Once you have initiated the command, there is no need to 'babysit' the
installation. It all happens automatically.

You can use the stored configuration to repeat the same installation if you need
to.

## Overview

If you have machines on a mix of platforms, you'll need a common installation
solution that works anywhere. **nixos-anywhere** is ideal in this situation.

**nixos-anywhere** can be used equally well for cloud servers, bare metal
servers such as Hetzner, and local servers accessible via a LAN. You can create
standard configurations, and use the same configuration to create identical
servers anywhere.

You first create Nix configurations to specify partitioning, formatting and
NixOS configurations. Further options can be controlled by a flake and by
run-time switches.

Once the configuration has been created, a single command will:

- Connect to the remote server via SSH
- Detect whether a NixOS installer is present; if not, it will use the Linux
  `kexec` tool to boot into a Nixos installer.
- Use the [disko](https://github.com/nix-community/disko) tool to partition and
  format the hard drive
- Install NixOS
- Optionally install any Nix packages and other software required.
- Optionally copy additional files to the new machine

It's also possible to use **nixos-anywhere** to simplify the installation on a
machine that has no current operating system, first booting from a NixOS
installer image. This feature is described in the
[how-to guide](./docs/howtos/no-os.md#installing-on-a-machine-with-no-operating-system).
It's useful because you can pre-configure your required software and
preferences, and build the new machine with a single command.

**Important Note:** Never use a production server as the target. It will be
completely overwritten and all data lost. This tool should only be used for
commissioning a new computer or repurposing an old machine once all important
data has been migrated.

## Prerequisites

- Source Machine:

  - Can be any machine with Nix installed, e.g. a NixOS machine.

- Target Machine:

  - Unless you're using the option to boot from a NixOS installer image, or
    providing your own `kexec` image, it must be running x86-64 Linux with kexec
    support. Most `x86_64` Linux systems do have kexec support. By providing
    your own [image](./docs/howtos/custom-kexec.md#using-your-own-kexec-image)
    you can also perform kexec for other architectures eg aarch64
  - The machine must be reachable over the public internet or local network.
    Nixos-anywhere does not support wifi networks. If a VPN is needed, define a
    custom installer via the --kexec flag which connects to your VPN.
  - When `kexec` is used the target must have at least 1 GB of RAM, excluding
    swap.

## How to use nixos-anywhere

The [Quickstart Guide](./docs/quickstart.md) gives more information on how to
run **nixos-anywhere** in its simplest form. For more specific instructions to
suit individual requirements, see the [How To Guide](./docs/howtos/INDEX.md).

## Related Tools

**nixos-anywhere** makes use of the
[disko](https://github.com/nix-community/disko) tool to handle the partitioning
and formatting of the disks.

## Contact

For questions, come join us in the
[nixos-anywhere](https://matrix.to/#/#nixos-anywhere:nixos.org) matrix room.

## Licensing and Contribution details

This software is provided free under the
[MIT License](https://opensource.org/licenses/MIT).

---

This project is supported by [Numtide](https://numtide.com/).
![Untitledpng](https://codahosted.io/docs/6FCIMTRM0p/blobs/bl-sgSunaXYWX/077f3f9d7d76d6a228a937afa0658292584dedb5b852a8ca370b6c61dabb7872b7f617e603f1793928dc5410c74b3e77af21a89e435fa71a681a868d21fd1f599dd10a647dd855e14043979f1df7956f67c3260c0442e24b34662307204b83ea34de929d)

We are a team of independent freelancers that love open source.  We help our
customers make their project lifecycles more efficient by:

- Providing and supporting useful tools such as this one
- Building and deploying infrastructure, and offering dedicated DevOps support
- Building their in-house Nix skills, and integrating Nix with their workflows
- Developing additional features and tools
- Carrying out custom research and development.

[Contact us](https://numtide.com/contact) if you have a project in mind, or if
you need help with any of our supported tools, including this one. We'd love to
hear from you.
