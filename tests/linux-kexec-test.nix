{ pkgs, nixos-anywhere, kexec-installer, nix-vm-test, system-to-install, distribution, version, ... }:

(nix-vm-test.lib.${pkgs.system}.${distribution}.${version} {
  sharedDirs = { };

  # Configure VM with 2GB memory
  machineConfigModule = { ... }: {
    nodes.vm.virtualisation.memorySize = 1500;
  };

  # The test script
  testScript = ''
    # Python imports
    import subprocess
    import tempfile
    import shutil
    import os

    # Wait for the system to be fully booted
    vm.wait_for_unit("multi-user.target")

    # Detect SSH service name (ssh on Ubuntu/Debian, sshd on Fedora/RHEL)
    ssh_service = "sshd" if "${distribution}" in ["fedora", "centos", "rhel"] else "ssh"

    # Unmask SSH service (which is masked by default in the test VM)
    vm.succeed(f"systemctl unmask {ssh_service}.service || true")
    vm.succeed(f"systemctl unmask {ssh_service}.socket || true")

    # Generate SSH host keys (required for SSH to start)
    vm.succeed("ssh-keygen -A")

    # Setup SSH with the existing keys
    vm.succeed("mkdir -p /root/.ssh")
    vm.succeed(
      "echo '${builtins.replaceStrings ["\n"] [""] (builtins.readFile ./modules/ssh-keys/ssh.pub)}' > /root/.ssh/authorized_keys"
    )
    vm.succeed("chmod 644 /root/.ssh/authorized_keys")

    # Setup SSH for connection from host
    vm.succeed(
      "sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config"
    )

    # Start SSH service
    vm.succeed(f"systemctl start {ssh_service}")

    # Forward SSH port using vm.forward_port method
    ssh_port = 2222
    vm.forward_port(host_port=ssh_port, guest_port=22)

    # Use temporary file for SSH key with automatic cleanup
    with tempfile.NamedTemporaryFile(mode='w', delete=True, suffix='_ssh_key') as temp_key:
      temp_key_path = temp_key.name

      # Copy SSH private key to temp file with correct permissions
      shutil.copy2("${./modules/ssh-keys/ssh}", temp_key_path)
      os.chmod(temp_key_path, 0o600)

      nixos_anywhere_cmd = [
        "${nixos-anywhere}/bin/nixos-anywhere",
        "-i", temp_key_path,
        "--ssh-port", str(ssh_port),
        "--post-kexec-ssh-port", "2222",
        "--phases", "kexec",
        "--kexec", "${kexec-installer}",
        "--store-paths", "${system-to-install.config.system.build.diskoScriptNoDeps}",
        "${system-to-install.config.system.build.toplevel}",
        "--debug",
        "root@localhost"
      ]

      result = subprocess.run(nixos_anywhere_cmd, check=False)

      if result.returncode != 0:
        print(f"nixos-anywhere failed with exit code {result.returncode}")
        vm.succeed("dmesg | tail -n 50")
        vm.succeed("journalctl -n 50")
        raise Exception(f"nixos-anywhere command failed with exit code {result.returncode}")

      # Test SSH connection to verify we're in NixOS kexec environment
      check_cmd = [
        "${pkgs.openssh}/bin/ssh", "-v",
        "-i", temp_key_path,
        "-p", "2222",
        "-o", "StrictHostKeyChecking=no",
        "-o", "UserKnownHostsFile=/dev/null",
        "root@localhost",
        "cat /etc/os-release"
      ]

      test_result = subprocess.run(check_cmd, check=True, stdout=subprocess.PIPE, text=True)
      assert "nixos" in test_result.stdout.lower(), f"Expected NixOS environment but got: {test_result.stdout}"

    # After kexec we no longer have the machine driver,
    # so we need to let the VM crash because the test driver backdoor gets confused by the terminal output.
    vm.crash()
  '';
}).sandboxed
