# Kexec on Systems with Limited RAM

When working with nixos-anywhere on systems with limited RAM (around 1GB), you
can use the `--no-disko-deps` option to reduce memory usage during installation.

## How it works

The `--no-disko-deps` option uploads only the disko partitioning script without
including its dependencies. This significantly reduces memory usage because:

1. The installer normally stores all dependencies in memory
2. Partitioning tools can be quite large when bundled with their dependencies

## Usage example

```bash
nix run github:nix-community/nixos-anywhere -- --no-disko-deps --flake <path to configuration>#<configuration name> --target-host root@<ip address>
```

## Trade-off

While this approach saves memory, it means the partitioning tools will be
whatever versions are available on the target system, rather than the specific
versions defined in your NixOS configuration. This could potentially lead to
version inconsistencies between the partitioning tools and the NixOS system
being installed.

This trade-off is usually acceptable for memory-constrained environments where
installation would otherwise fail due to insufficient RAM.
