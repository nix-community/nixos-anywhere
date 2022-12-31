(import ./lib/test-base.nix) {
  name = "nixos-remote";
  nodes = {
    installer = ./modules/installer.nix;
    installed = ./modules/installed.nix;
  };
  testScript = ''
    start_all()
    installer.succeed("""
      eval $(ssh-agent)
      ssh-add /etc/sshKey
      ${../nixos-remote} \
        --no-ssh-copy-id \
        --debug \
        --kexec /etc/nixos-remote/kexec-installer \
        --stop-after-disko \
        --store-paths /etc/nixos-remote/disko /etc/nixos-remote/system-to-install \
        nixos@installed >&2
    """)
  '';
}
