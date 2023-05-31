# System Requirements: nixos-anywhere

**_Install NixOS everywhere via ssh_**

<img src="https://raw.githubusercontent.com/numtide/nixos-anywhere/main/docs/logo.png" width="150" height="150">

[Documentation Index](./INDEX.md)

## Requirements

- Source Machine:
  - Can be any Linux or Mac computer with Nix installed, or a NixOS machine.
- Destination Machine:
  - Must be an x86-64 machine unless you are able to supply a `kexec` image for
    your CPU type.
  - If you're not using the option to boot from a Nixos installer image, it
    must:
    - Be running x86-64 Linux with kexec support . Most x86_64 Linux systems do
      have kexec support.
    - Have at least 2.5 GB of RAM, excluding swap.
