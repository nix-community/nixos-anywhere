(import ./lib/test-base.nix) {
  name = "from-nixos-generate-config";
  nodes = {
    installer = { pkgs, ... }: {
      imports = [
        ./modules/installer.nix
      ];
      environment.systemPackages = [ pkgs.jq ];
    };
    installed = {
      services.openssh.enable = true;
      virtualisation.memorySize = 1500;

      users.users.root.openssh.authorizedKeys.keyFiles = [ ./modules/ssh-keys/ssh.pub ];
    };
  };
  testScript = ''
    start_all()
    installer.fail("test -f /tmp/hw/config.nix")
    installer.succeed("echo super-secret > /tmp/disk-1.key")
    output = installer.succeed("""
      nixos-anywhere \
        -i /root/.ssh/install_key \
        --debug \
        --kexec /etc/nixos-anywhere/kexec-installer \
        --disk-encryption-keys /tmp/disk-1.key /tmp/disk-1.key \
        --disk-encryption-keys /tmp/disk-2.key <(echo another-secret) \
        --phases kexec,disko \
        --generate-hardware-config nixos-generate-config /tmp/hw/config.nix \
        --store-paths /etc/nixos-anywhere/disko /etc/nixos-anywhere/system-to-install \
        root@installed >&2
      echo "disk-1.key: '$(ssh -i /root/.ssh/install_key -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
        root@installed cat /tmp/disk-1.key)'"
      echo "disk-2.key: '$(ssh -i /root/.ssh/install_key -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
        root@installed cat /tmp/disk-2.key)'"
    """)

    installer.succeed("cat /tmp/hw/config.nix >&2")
    installer.succeed("nix-instantiate --parse /tmp/hw/config.nix")

    assert "disk-1.key: 'super-secret'" in output, f"output does not contain expected values: {output}"
    assert "disk-2.key: 'another-secret'" in output, f"output does not contain expected values: {output}"

    installer.fail("test -f /test/hw/config.json")

    output = installer.succeed("""
      nixos-anywhere \
        -i /root/.ssh/install_key \
        --debug \
        --kexec /etc/nixos-anywhere/kexec-installer \
        --disk-encryption-keys /tmp/disk-1.key /tmp/disk-1.key \
        --disk-encryption-keys /tmp/disk-2.key <(echo another-secret) \
        --phases kexec,disko \
        --generate-hardware-config nixos-facter /tmp/hw/config.json \
        --store-paths /etc/nixos-anywhere/disko /etc/nixos-anywhere/system-to-install \
        installed >&2
      echo "disk-1.key: '$(ssh -i /root/.ssh/install_key -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
        root@installed cat /tmp/disk-1.key)'"
      echo "disk-2.key: '$(ssh -i /root/.ssh/install_key -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
        root@installed cat /tmp/disk-2.key)'"
    """)

    installer.succeed("cat /tmp/hw/config.json >&2")
    installer.succeed("jq < /tmp/hw/config.json")

    assert "disk-1.key: 'super-secret'" in output, f"output does not contain expected values: {output}"
    assert "disk-2.key: 'another-secret'" in output, f"output does not contain expected values: {output}"
  '';
}
