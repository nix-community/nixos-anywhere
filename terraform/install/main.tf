resource "null_resource" "nixos-remote" {
  triggers = {
    instance_id = var.instance_id
  }
  provisioner "local-exec" {
    environment = {
      SSH_PRIVATE_KEY = var.ssh_private_key
      stop_after_disko = var.stop_after_disko
      debug_logging = var.debug_logging
      kexec_tarball_url = var.kexec_tarball_url
      nixos_partitioner = var.nixos_partitioner
      nixos_system = var.nixos_system
      target_user = var.target_user
      target_host = var.target_host
      extra_files_script = var.extra_files_script
    }
    command = "bash run-nixos-anywhere.sh"
    quiet   = var.debug_logging
  }
}
