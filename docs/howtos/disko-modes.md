# Repair installations without wiping data

By default, nixos-anywhere will reformat all configured disks before running the
installation. However it is also possible to mount the filesystems of an
existing installation and run `nixos-install`. This is useful to recover from a
misconfigured NixOS installation by first booting into a NixOS installer or
recovery system.

To only mount existing filesystems, add `--disko-mode mount` to
`nixos-anywhere`:

```
nix run github:nix-community/nixos-anywhere -- --disko-mode mount --flake <path to configuration>#<configuration name> --target-host root@<ip address>
```

1. This will first boot into a nixos-installer
2. Mounts disks with disko
3. Runs nixos-install based on the provided flake
4. Reboots the machine.
