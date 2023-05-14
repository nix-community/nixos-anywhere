To run `nixos-anywhere` from the repo:

```console
nix run . -- --help
```

To format the code:

```console
nix fmt
```

To run all tests:

```console
nix flake check -vL
```

To run an individual test:

```
nix build .#checks.x86_64-linux.from-nixos -vL
```
