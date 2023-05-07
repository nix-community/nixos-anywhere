{ modulesPath, self, ... }: {
  imports = [
    (modulesPath + "/testing/test-instrumentation.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    (modulesPath + "/profiles/minimal.nix")
  ];
  networking.hostName = "nixos-anywhere";
  documentation.enable = false;
  hardware.enableAllFirmware = false;
  networking.hostId = "8425e349"; # from profiles/base.nix, needed for zfs
  boot.zfs.devNodes = "/dev/disk/by-uuid"; # needed because /dev/disk/by-id is empty in qemu-vms
  boot.loader.grub.devices = [ "/dev/vda" ];
  disko.devices = {
    disk = {
      vda = {
        device = "/dev/vda";
        type = "disk";
        content = {
          type = "table";
          format = "gpt";
          partitions = [
            {
              name = "boot";
              start = "0";
              end = "1M";
              part-type = "primary";
              flags = [ "bios_grub" ];
            }
            {
              name = "ESP";
              start = "1MiB";
              end = "100MiB";
              bootable = true;
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            }
            {
              name = "root";
              start = "100MiB";
              end = "100%";
              part-type = "primary";
              bootable = true;
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            }
          ];
        };
      };
    };
  };
}
