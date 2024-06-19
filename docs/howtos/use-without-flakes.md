# Use without flakes

First,
[import the disko NixOS module](https://github.com/nix-community/disko/blob/master/docs/HowTo.md#installing-nixos-module)
in your NixOS configuration and define disko devices as described in the
[examples](https://github.com/nix-community/disko/tree/master/example).

Let's assume that your NixOS configuration lives in `configuration.nix` and your
target machine is called `machine`.

```nix
# configuration.nix
{
  pkgs ? import (fetchTarball channel:nixos-24.05) {};
}:
{
  config = { config, pkgs, ... }: { /* ... */ };
  machine = pkgs.nixos config;
}
```

Generate the disk formatting script:

```bash
disko=$(nix-build configuration.nix -A machine.config.system.build.disko' --no-out-path)
```

Generate the store path that includes all the software and configurations for
the NixOS system:

```bash
nixos=$(nix-build configuration.nix -A machine.config.system.build.toplevel' --no-out-path)
```

Run `nixos-anywhere` as follows:

```bash
nixos-anywhere --store-paths $disko $nixos root@machine
```
