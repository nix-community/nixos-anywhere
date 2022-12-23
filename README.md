# nixos-remote - install nixos everywhere via ssh

nixos-remote makes it possible to install nixos from Linux machines reachable via ssh.
Under the hood uses a [kexec image](https://github.com/nix-community/nixos-images#kexec-tarballs) to boot
into a NixOS installer from a running Linux system.
It then uses [disko](https://github.com/nix-community/disko) to partition and
format the disks on the target system before it installs the user provided nixos
configuration.

## Requirements

- x86_64 Linux system with kexec support (most x86_64 machine do have kexec support)
- At least 2.5GB RAM (swap does not count). If you do not have enough RAM you
  will see failures unpacking the initrd), this is because kexec needs to load
  the whole nixos into memory.

## Usage
Needs a repo with your configurations with flakes. For a minimal example checkout https://github.com/Lassulus/flakes-testing.

Your NixOS configuration will also need a [disko](https://github.com/nix-community/disko) configuration  as we can see in
our [example](https://github.com/Lassulus/flakes-testing/blob/216b3023c01581359599f5bc9ae48eeee2617627/flake.nix#L13)

Afterwards you can just run:

```
./nixos-remote root@yourip --flake github:your-user/your-repo#your-system
```

The parameter passed to `--flake` should point to your nixos configuration
exposed in your flake (`nixosConfigurations.your-system` in the example above).
