(import ./lib/test-base.nix) (
  { pkgs, ... }:
  {
    name = "from-nixos";
    nodes = {
      installer = ./modules/installer.nix;
      installed = {
        services.openssh.enable = true;
        virtualisation.memorySize = 1500;

        users.users.root.openssh.authorizedKeys.keyFiles = [ ./modules/ssh-keys/ssh.pub ];
      };
    };
    testScript = ''
      def create_test_machine(
          oldmachine=None, **kwargs
      ):  # taken from <nixpkgs/nixos/tests/installer.nix>
          start_command = [
              "${pkgs.qemu_test}/bin/qemu-kvm",
              "-cpu",
              "max",
              "-m",
              "1024",
              "-virtfs",
              "local,path=/nix/store,security_model=none,mount_tag=nix-store",
              "-drive",
              f"file={oldmachine.state_dir}/installed.qcow2,id=drive1,if=none,index=1,werror=report",
              "-device",
              "virtio-blk-pci,drive=drive1",
          ]
          machine = create_machine(start_command=" ".join(start_command), **kwargs)
          driver.machines.append(machine)
          return machine
      start_all()
      installer.succeed("mkdir -p /tmp/extra-files/var/lib/secrets")
      installer.succeed("echo value > /tmp/extra-files/var/lib/secrets/key")
      installer.succeed("mkdir -p /tmp/extra-files/home/user/.ssh")
      installer.succeed("echo secretkey > /tmp/extra-files/home/user/.ssh/id_ed25519")
      installer.succeed("echo publickey > /tmp/extra-files/home/user/.ssh/id_ed25519.pub")
      installer.succeed("chmod 600 /tmp/extra-files/home/user/.ssh/id_ed25519")
      ssh_key_path = "/etc/ssh/ssh_host_ed25519_key.pub"
      ssh_key_output = installer.wait_until_succeeds(f"""
        ssh -i /root/.ssh/install_key -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
          root@installed cat {ssh_key_path}
      """)
      installer.succeed("""
        nixos-anywhere \
          -i /root/.ssh/install_key \
          --debug \
          --kexec /etc/nixos-anywhere/kexec-installer \
          --extra-files /tmp/extra-files \
          --store-paths /etc/nixos-anywhere/disko /etc/nixos-anywhere/system-to-install \
          --chown /home/user 1000:100 \
          --copy-host-keys \
          root@installed >&2
      """)
      try:
        installed.shutdown()
      except BrokenPipeError:
        # qemu has already exited
        pass
      new_machine = create_test_machine(oldmachine=installed, name="after_install")
      new_machine.start()
      hostname = new_machine.succeed("hostname").strip()
      assert "nixos-anywhere" == hostname, f"'nixos-anywhere' != '{hostname}'"
      content = new_machine.succeed("cat /var/lib/secrets/key").strip()
      assert "value" == content, f"secret does not have expected value: {content}"
      ssh_key_content = new_machine.succeed(f"cat {ssh_key_path}").strip()
      assert ssh_key_content in ssh_key_output, "SSH host identity changed"
      priv_key_perms = new_machine.succeed("stat -c %a /home/user/.ssh/id_ed25519").strip()
      assert priv_key_perms == "600", f"unexpected permissions for private key: {priv_key_perms}"
      user_dir_ownership = new_machine.succeed("stat -c %u:%g /home/user").strip()
      assert user_dir_ownership == "1000:100", f"unexpected user home dir permissions: {user_dir_ownership}"
    '';
  }
)
