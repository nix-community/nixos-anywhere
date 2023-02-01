(import ./lib/test-base.nix) {
  name = "from-nixos";
  nodes = {
    installer = ./modules/installer.nix;
    installed = {
      services.openssh.enable = true;
      virtualisation.memorySize = 4096;

      users.users.root.openssh.authorizedKeys.keyFiles = [ ./modules/ssh-keys/ssh.pub ];
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
    installer.succeed("mkdir -p /tmp/extra-files/var/lib/secrets")
    installer.succeed("echo value > /tmp/extra-files/var/lib/secrets/key")
    installer.succeed("""
      nixos-anywhere \
        --debug \
        --kexec /etc/nixos-anywhere/kexec-installer \
        --extra-files /tmp/extra-files \
        --store-paths /etc/nixos-anywhere/disko /etc/nixos-anywhere/system-to-install \
        root@installed >&2
    """)
    installed.shutdown()
    new_machine = create_test_machine(oldmachine=installed, args={ "name": "after_install" })
    new_machine.start()
    hostname = new_machine.succeed("hostname").strip()
    assert "nixos-anywhere" == hostname, f"'nixos-anywhere' != '{hostname}'"
    content = new_machine.succeed("cat /var/lib/secrets/key").strip()
    assert "value" == content, f"secret does not have expected value: {content}"
  '';
}
