# System Requirements: nixos-anywhere

**_Install NixOS everywhere via ssh_**

<img src="https://raw.githubusercontent.com/numtide/nixos-anywhere/main/docs/logo.png" width="150" height="150">

## 

- Source Machine:
  - Can be any Linux or Mac computer with Nix installed, or a NixOS machine.
- Destination Machine:
  - Must be an x86-64 machine
  - Unless you're using the option to boot from a Nixos installer image, it must be running x86-64 Linux with kexec support . Most x86_64 Linux systems do have kexec support.
  - Must have at least 2.5 GB of RAM, excluding swap.
