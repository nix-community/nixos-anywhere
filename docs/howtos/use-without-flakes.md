# Use without flakes

While `nixos-anywhere` is designed to work optimally with Nix Flakes, it also
supports the traditional approach without flakes. This document outlines how to
use `nixos-anywhere` without relying on flakes. You will need to
[import the disko nixos module](https://github.com/nix-community/disko/blob/master/docs/HowTo.md#installing-nixos-module)
in your NixOS configuration and define disko devices as described in the
[examples](https://github.com/nix-community/disko/tree/master/example).

## Generate Required Store Paths

Before you can use `nixos-anywhere` without flakes, you'll need to manually
generate the paths for the NixOS system toplevel and disk image. The paths are
generated using `nix-build` and are necessary for executing `nixos-anywhere`.

### Generating NixOS System Toplevel:

Execute the following command to generate the store path for the NixOS system
toplevel:

```bash
nix-build -I nixos-config=/etc/nixos/configuration.nix -E '(import <nixpkgs/nixos> {}).config.system.build.toplevel'
```

This will output a path in `/nix/store` that corresponds to the system toplevel,
which includes all the software and configurations for the system. Make note of
this path for later use.

### Generating Disk Image without Dependencies:

To generate the disk image without dependencies, execute:

```bash
nix-build -I nixos-config=/etc/nixos/configuration.nix -E '(import <nixpkgs/nixos> {}).config.system.build.diskoNoDeps'
```

This will also output a script path in `/nix/store` that will format your disk.
Keep this path handy as well.

## Running NixOS-Anywhere

With both paths in hand, you can execute `nixos-anywhere` as follows:

```bash
nixos-anywhere --store-paths /nix/store/[your-toplevel-path] /nix/store/[your-disk-image-path]
```

Replace `[your-toplevel-path]` and `[your-disk-image-path]` with the
corresponding store paths you generated earlier.
