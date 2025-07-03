# Use without flakes

First,
[import the disko NixOS module](https://github.com/nix-community/disko/blob/master/docs/HowTo.md#installing-nixos-module)
in your NixOS configuration and define disko devices as described in the
[examples](https://github.com/nix-community/disko/tree/master/example).

Let's assume that your NixOS configuration lives in `configuration.nix` and your
target machine is called `machine`:

## 1. Download your favourite disk layout:

See https://github.com/nix-community/disko-templates/ for more examples:

The example below will work with both UEFI and BIOS-based systems.

```bash
curl https://raw.githubusercontent.com/nix-community/disko-templates/main/single-disk-ext4/disko-config.nix > ./disko-config.nix
```

## 2. Get a hardware-configuration.nix from on the target machine

- **Option 1**: If NixOS is not installed, boot into an installer without first
  installing NixOS.
- **Option 2**: Use the kexec tarball method, as described
  [here](https://github.com/nix-community/nixos-images#kexec-tarballs).

- **Generate Configuration**: Run the following command on the target machine:

  ```bash
  nixos-generate-config --no-filesystems --dir /tmp/config
  ```

This creates the necessary configuration files under `/tmp/config/`. Copy
`/tmp/config/nixos/hardware-configuration.nix` to your local machine into the
same directory as `disko-config.nix`.

## 3. Set NixOS version to use

```nix
# default.nix
let
  # replace nixos-24.11 with your preferred nixos version or revision from here: https://status.nixos.org/
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/archive/refs/heads/nixos-24.11.tar.gz";
in
import (nixpkgs + "/nixos/lib/eval-config.nix") {
  modules = [ ./configuration.nix ];
}
```

## 4. Write a NixOS configuration

```nix
# configuration.nix
{
  imports = [
   "${fetchTarball "https://github.com/nix-community/disko/tarball/master"}/module.nix"
    ./disko-config.nix
    ./hardware-configuration.nix
  ];
  # Replace this with the system of the installation target you want to install!!!
  disko.devices.disk.main.device = "/dev/sda";

  # Set this to the NixOS version that you have set in the previous step.
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.11";
}
```

## 5. Build and deploy with nixos-anywhere

Your current directory now should contain the following files from the previous
step:

- `configuration.nix`, `default.nix`, `disko-config.nix` and
  `hardware-configuration.nix`

Run `nixos-anywhere` as follows:

```bash
nixos-anywhere --store-paths $(nix-build -A config.system.build.diskoScript -A config.system.build.toplevel --no-out-link) root@machine
```
