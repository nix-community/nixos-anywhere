(import ./lib/test-base.nix) {
  name = "from-nixos-with-sudo";
  nodes = {
    installer = ./modules/installer.nix;
    installed = ./modules/installed.nix;
  };
  testScript = ''
    start_all()
    installer.succeed("echo super-secret > /tmp/disk-encryption-key")
    output = installer.succeed("""
      ${../nixos-remote} \
        --no-ssh-copy-id \
        --debug \
        --kexec /etc/nixos-remote/kexec-installer \
        --stop-after-disko \
        --disk-encryption-keys /tmp/disk-encryption-key \
        --store-paths /etc/nixos-remote/disko /etc/nixos-remote/system-to-install \
        nixos@installed >&2
      key=$(ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
        root@installed cat /tmp/disk-encryption-key)
      echo "encryption key: '$key'"
    """)

    assert "encryption key: 'super-secret'" in output, f"output does not contain expected values: {output}"
  '';
}
