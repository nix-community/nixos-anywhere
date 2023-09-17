# NixOS-Anywhere Terraform Modules Overview

The nixos-Anywhere terraform modules allow you to use Terraform for installing
and updating NixOS. It simplifies the deployment process by integrating
nixos-anywhere functionality.

Here's a brief overview of each module:

- **[All-in-One](all-in-one.md)**: This is a consolidated module that first
  installs NixOS using nixos-anywhere and then keeps it updated with
  nixos-rebuild. If you choose this, you won't need additional deployment tools
  like colmena.
- **[Install](install.md)**: This module focuses solely on installing NixOS via
  nixos-anywhere.
- **[NixOS-Rebuild](nixos-rebuild.md)**: Use this module to remotely update an
  existing NixOS machine using nixos-rebuild.
- **[Nix-Build](nix-build.md)**: This is a handy helper module designed to build
  a flake attribute or an attribute from a nix file.

For detailed information and usage examples, click on the respective module
links above.
