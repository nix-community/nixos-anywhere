(import ./lib/test-base.nix) {
  name = "from-nixos-installer-with-sudo";
  nodes = {
    installer = ./modules/installer.nix;
    installed = { modulesPath, ... }: {
      imports = [
        (modulesPath + "/installer/cd-dvd/installation-cd-base.nix")
      ];

      services.openssh.enable = true;
      virtualisation.memorySize = 1500;
      virtualisation.emptyDiskImages = [ 1024 ];

      users.users.nixos = {
        isNormalUser = true;
        openssh.authorizedKeys.keyFiles = [ ./modules/ssh-keys/ssh.pub ];
        extraGroups = [ "wheel" ];
      };
      security.sudo.enable = true;
      security.sudo.wheelNeedsPassword = false;

      # Configure nix trusted users for remote builds with sudo
      nix.settings.trusted-users = [ "root" "nixos" ];
    };
  };
  testScript = ''
    start_all()
    installer.succeed("echo super-secret > /tmp/disk-1.key")
    installer.succeed("mkdir -p /tmp/extra-files/var/lib/secrets")
    installer.succeed("echo test-value > /tmp/extra-files/var/lib/secrets/test")

    output = installer.succeed("""
      nixos-anywhere \
        -i /root/.ssh/install_key \
        --debug \
        --phases disko,install \
        --disk-encryption-keys /tmp/disk-1.key /tmp/disk-1.key \
        --extra-files /tmp/extra-files \
        --store-paths /etc/nixos-anywhere/disko /etc/nixos-anywhere/system-to-install \
        nixos@installed >&2
      echo "disk-1.key: '$(ssh -i /root/.ssh/install_key -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
        nixos@installed sudo cat /tmp/disk-1.key)'"
      echo "extra-file: '$(ssh -i /root/.ssh/install_key -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
        nixos@installed sudo cat /mnt/var/lib/secrets/test)'"
    """)

    assert "disk-1.key: 'super-secret'" in output, f"output does not contain expected values: {output}"
    assert "extra-file: 'test-value'" in output, f"output does not contain expected values: {output}"
  '';
}
