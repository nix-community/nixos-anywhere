# Nix-channels / `NIX_PATH`

nixos-anywhere does not install channels onto the new system by default to save
time and disk space. This for example results in errors like:

```
(stack trace truncated; use '--show-trace' to show the full trace)

error: file 'nixpkgs' was not found in the Nix search path (add it using $NIX_PATH or -I)

at «none»:0: (source not available)
```

when using tools like nix-shell/nix-env that rely on `NIX_PATH` being set.

# Solution 1: Set the `NIX_PATH` via nixos configuration (recommended)

Instead of stateful channels, one can also populate the `NIX_PATH` using nixos
configuration instead:

```nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  # ... other inputs

  outputs = inputs@{ nixpkgs, ... }:
    {
      nixosConfigurations.yoursystem = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux"; # adapt to your actual system
        modules = [
          # This line will populate NIX_PATH
          { nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ]; }
          # ... other modules and your configuration.nix
        ];
      };
    };
}
```

Advantage: This solution will be automatically kept up-to-date every time the
flake is updated.

In your shell you will see something in your `$NIX_PATH`:

```shellSession
$ echo $NIX_PATH
/root/.nix-defexpr/channels:nixpkgs=/nix/store/8b61j28rpy11dg8hanbs2x710d8w3v0d-source
```

# Solution 2: Manually add the channel

On the installed machine, run:

```shellSession
$ nix-channel --add https://nixos.org/channels/nixos-unstable nixos
$ nix-channel --update
```
