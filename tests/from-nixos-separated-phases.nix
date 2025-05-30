(import ./lib/test-base.nix) {
  name = "from-nixos-separated-phases";
  nodes = {
    installer = ./modules/installer.nix;
    installed = {
      services.openssh.enable = true;
      virtualisation.memorySize = 1500;

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

    with subtest("Kexec Phase"):
      installer.succeed("""
        nixos-anywhere \
          -i /root/.ssh/install_key \
          --debug \
          --kexec /etc/nixos-anywhere/kexec-installer \
          --phases kexec \
          --store-paths /etc/nixos-anywhere/disko /etc/nixos-anywhere/system-to-install \
          nixos@installed >&2
      """)

    with subtest("Disko Phase"):
      output = installer.succeed("""
        nixos-anywhere \
          -i /root/.ssh/install_key \
          --debug \
          --phases disko \
          --store-paths /etc/nixos-anywhere/disko /etc/nixos-anywhere/system-to-install \
          installed >&2
    """)

    with subtest("Install Phase"):
      installer.succeed("""
        nixos-anywhere \
          -i /root/.ssh/install_key \
          --debug \
          --phases install \
          --store-paths /etc/nixos-anywhere/disko /etc/nixos-anywhere/system-to-install \
          root@installed >&2 
      """)
  '';
}
