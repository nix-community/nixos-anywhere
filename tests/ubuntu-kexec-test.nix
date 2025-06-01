{ pkgs, nixos-anywhere, kexec-installer, nix-vm-test, ... }:

let
  # Create dummy store paths for testing
  testPaths = pkgs.runCommand "test-store-paths" {} ''
    mkdir -p $out
    echo "echo 'Dummy disko script'" > $out/disko
    echo "echo 'Dummy system closure'" > $out/system
    chmod +x $out/disko $out/system
  '';
in
nix-vm-test.ubuntu."22_04" {
  memorySize = 2048;

  # Forward SSH port to allow connection from the host
  virtualisation.forwardPorts = [
    { from = "host"; host.port = 2222; guest.port = 22; }
  ];

  # Make the SSH keys available in the VM
  sharedDirs = {
    sshKeys = {
      source = "${nixos-anywhere}/tests/modules/ssh-keys";
      target = "/tmp/ssh-keys";
    };
  };

  # The test script
  testScript = ''
    # Wait for the system to be fully booted
    vm.wait_for_unit("multi-user.target")

    # Unmask SSH service (which is masked by default in the test VM)
    vm.succeed("systemctl unmask ssh.service")
    vm.succeed("systemctl unmask ssh.socket")
    vm.succeed("systemctl start ssh")

    # Setup SSH with the existing keys
    vm.succeed("mkdir -p /root/.ssh")
    vm.succeed("cp /tmp/ssh-keys/ssh.pub /root/.ssh/authorized_keys")
    vm.succeed("chmod 644 /root/.ssh/authorized_keys")

    # Setup SSH for connection from host
    vm.succeed("sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config")
    vm.succeed("systemctl restart ssh")
    
    # Wait for SSH to be available
    vm.wait_for_open_port(22)
    print("SSH server is ready")

    # Run nixos-anywhere from the host against the VM
    print("Starting kexec test phase...")
    
    # Use Python's subprocess to run nixos-anywhere from the host
    import subprocess
    
    cmd = f"""${nixos-anywhere}/bin/nixos-anywhere \\
      -i ${nixos-anywhere}/tests/modules/ssh-keys/ssh \\
      --ssh-port 2222 \\
      --phases kexec \\
      --kexec ${kexec-installer} \\
      --store-paths ${testPaths}/disko ${testPaths}/system \\
      --debug \\
      root@localhost
    """
    
    print(f"Running command: {cmd}")
    result = subprocess.run(cmd, shell=True, check=False)
    
    if result.returncode == 0:
      print("kexec phase completed successfully")
    else:
      print(f"nixos-anywhere failed with exit code {result.returncode}")
      raise Exception("nixos-anywhere command failed")
  '';
}