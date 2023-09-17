# nixos-anywhere terraform modules

These terraform module can run nixos-anywhere from terraform to install nixos as
well as deploying nixos afterwards.

See what each module does with examples by clicking on the terraform module in
the following links below:

- [all-in-one](all-in-one.md): Combines the install and nixos-rebuild module in
  one interface to install NixOS with nixos-anywhere and than keep it up-to-date
  with nixos-rebuild.
- [install](install.md): Install NixOS with nixos-anywhere
- [nixos-rebuild](nixos-rebuild.md): Update NixOS machine with nixos-rebuild on
  a remote machine
- [nix-build](nix-build.md): Small helper module to run do build a flake
  attribute or attribute from a nix file.
