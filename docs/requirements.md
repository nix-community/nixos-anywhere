# System Requirements: nixos-anywhere

**_Install NixOS everywhere via ssh_**

<img src="https://raw.githubusercontent.com/numtide/nixos-anywhere/main/docs/logo.png" width="150" height="150">

[Documentation Index](./INDEX.md)

## Requirements

### Source Machine:

1. **Supported Systems:**
   - Linux or macOS computers with Nix installed.
   - NixOS
   - Windows systems using WSL2.

2. **Nix Installation:** If Nix is not yet installed on your system, refer to
   the [nix installation page](https://nixos.org/download#download-nix).

### Destination Machine:

1. **Direct Boot Option:**
   - Must be already running a NixOS installer.

2. **Alternative Boot Options:** If not booting directly from a NixOS installer
   image:
   - **Architecture & Support:** Must be operating on:
     - x86-64 or aarch64 Linux systems with kexec support. Note: While most
       x86-64 Linux systems support kexec, if you're using an architecture other
       than those mentioned, you may need to specify a
       [different kexec image](./howtos.md#using-your-own-kexec-image) manually.
   - **Memory Requirements:**
     - At least 1.5 GB of RAM (excluding swap space).
