# nixos-remote - install nixos everywhere via ssh

## Usage
Needs a repo with your configurations with flakes. for a minimal example checkout https://github.com/Lassulus/flakes-testing.

Your NixOS configuration will also need a [disko](https://github.com/nix-community/disko) configuration  as we can see in
our [example](https://github.com/Lassulus/flakes-testing/blob/216b3023c01581359599f5bc9ae48eeee2617627/flake.nix#L13)

Afterwards you can just run:

```
./nixos-remote root@yourip --flake github:your-user/your-repo#your-system
```

The parameter passed to `--flake` should point to your nixos configuration
exposed in your flake (`nixosConfigurations.your-system` in the example above).

Currently nixos-remote requires that the network of the machine, offers DHCP for
dynamic address configuration or else the booted nixos will not have any
network set up.
