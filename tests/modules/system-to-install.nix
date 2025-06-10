{ modulesPath, lib, config, ... }:
{
  options.nixos-anywhere.diskDevice = lib.mkOption {
    type = lib.types.str;
    default = "/dev/vda";
    description = "The disk device to use for installation";
  };

  imports = [
    (modulesPath + "/testing/test-instrumentation.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    (modulesPath + "/profiles/minimal.nix")
  ];

  config = {
    networking.hostName = lib.mkDefault "nixos-anywhere";
    documentation.enable = false;
    hardware.enableAllFirmware = false;
    networking.hostId = "8425e349"; # from profiles/base.nix, needed for zfs
    boot.zfs.devNodes = "/dev/disk/by-uuid"; # needed because /dev/disk/by-id is empty in qemu-vms
    disko.devices = {
      disk = {
        main = {
          device = config.nixos-anywhere.diskDevice;
          type = "disk";
          content = {
            type = "gpt";
            partitions = {
              boot = {
                size = "1M";
                type = "EF02";
              };
              ESP = {
                size = "100M";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                };
              };
              root = {
                size = "100%";
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                };
              };
            };
          };
        };
      };
    };
  };
}
