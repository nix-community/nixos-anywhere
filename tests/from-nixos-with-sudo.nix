(import ./lib/test-base.nix) {
  name = "from-nixos-with-sudo";
  nodes = {
    installer = ./modules/installer.nix;
    installed = {
      services.openssh.enable = true;
      virtualisation.memorySize = 4096;

      users.users.nixos = {
        isNormalUser = true;
        openssh.authorizedKeys.keyFiles = [ ./modules/ssh-keys/ssh.pub ];
        extraGroups = [ "wheel" ];
      };
      security.sudo.enable = true;
      security.sudo.wheelNeedsPassword = false;
    };
  };
  testScript = ''
    start_all()
    installer.succeed("echo super-secret > /tmp/disk-1.key")
    output = installer.succeed("""
      nixos-remote \
        --debug \
        --kexec /etc/nixos-remote/kexec-installer \
        --stop-after-disko \
        --disk-encryption-keys /tmp/disk-1.key /tmp/disk-1.key \
        --disk-encryption-keys /tmp/disk-2.key <(echo another-secret) \
        --store-paths /etc/nixos-remote/disko /etc/nixos-remote/system-to-install \
        nixos@installed >&2
      echo "disk-1.key: '$(ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
        root@installed cat /tmp/disk-1.key)'"
      echo "disk-2.key: '$(ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
        root@installed cat /tmp/disk-2.key)'"
    """)

    assert "disk-1.key: 'super-secret'" in output, f"output does not contain expected values: {output}"
    assert "disk-2.key: 'another-secret'" in output, f"output does not contain expected values: {output}"
  '';
}
