{ pkgs ? import <nixpkgs> {}
, makeTest ? import <nixpkgs/nixos/tests/make-test-python.nix>
, eval-config ? import <nixpkgs/nixos/lib/eval-config.nix>
, disko ? "${builtins.fetchTarball "https://github.com/nix-community/disko/archive/master.tar.gz"}/module.nix"
, kexec-installer ? builtins.fetchurl "https://github.com/nix-community/nixos-images/releases/download/nixos-unstable/nixos-kexec-installer-${pkgs.stdenv.hostPlatform.system}.tar.gz"
, ... }:
let
  systemToInstall = { modulesPath, ... }: {
    imports = [
      disko
      (modulesPath + "/testing/test-instrumentation.nix")
      (modulesPath + "/profiles/qemu-guest.nix")
      (modulesPath + "/profiles/minimal.nix")
    ];
    networking.hostName = "nixos-remote";
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
                type = "partition";
                start = "0";
                end = "1M";
                part-type = "primary";
                flags = ["bios_grub"];
              }
              {
                type = "partition";
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
                type = "partition";
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
  };
  evaledSystem = eval-config {
    modules = [ systemToInstall ];
    system = "x86_64-linux";
  };
in
makeTest {
  name = "nixos-remote";
  nodes = {
    installer = {
      documentation.enable = false;
      environment.etc.sshKey = {
        source = ./ssh-keys/ssh;
        mode = "0600";
      };
      programs.ssh.startAgent = true;
      system.extraDependencies = [
        evaledSystem.config.system.build.disko
        evaledSystem.config.system.build.toplevel
      ];
    };
    installed = {
      virtualisation.memorySize = 4096;
      documentation.enable = false;
      services.openssh.enable = true;
      users.users.root.openssh.authorizedKeys.keyFiles = [ ./ssh-keys/ssh.pub ];
    };
  };
  testScript = ''
    def create_test_machine(oldmachine=None, args={}): # taken from <nixpkgs/nixos/tests/installer.nix>
        machine = create_machine({
          "qemuFlags":
            '-cpu max -m 1024 -virtfs local,path=/nix/store,security_model=none,mount_tag=nix-store,'
            f' -drive file={oldmachine.state_dir}/installed.qcow2,id=drive1,if=none,index=1,werror=report'
            f' -device virtio-blk-pci,drive=drive1',
        } | args)
        driver.machines.append(machine)
        return machine

    start_all()
    installed.wait_for_unit("sshd.service")
    installer.succeed("mkdir -p /tmp/extra-files/var/lib/secrets")
    installer.succeed("echo value > /tmp/extra-files/var/lib/secrets/key")
    installer.succeed("""
      eval $(ssh-agent)
      ssh-add /etc/sshKey
      ${../nixos-remote} \
        --no-ssh-copy-id \
        --debug \
        --kexec ${kexec-installer} \
        --extra-files /tmp/extra-files \
        --store-paths ${toString evaledSystem.config.system.build.disko} ${toString evaledSystem.config.system.build.toplevel} \
        root@installed >&2
    """)
    installed.shutdown()
    new_machine = create_test_machine(oldmachine=installed, args={ "name": "after_install" })
    new_machine.start()
    hostname = new_machine.succeed("hostname").strip()
    assert "nixos-remote" == hostname, f"'nixos-remote' != '{hostname}'"
    content = new_machine.succeed("cat /var/lib/secrets/key").strip()
    assert "value" == content, f"secret does not have expected value: {content}"
  '';
} {
  pkgs = pkgs;
  system = pkgs.system;
}
