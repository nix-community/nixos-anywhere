locals {
  disk_encryption_key_scripts = [for k in var.disk_encryption_key_scripts : "\"${k.path}\" \"${k.script}\""]
}

resource "null_resource" "nixos-remote" {
  triggers = {
    instance_id = var.instance_id
  }
  provisioner "local-exec" {
    environment = merge({
      SSH_PRIVATE_KEY = var.ssh_private_key
      stop_after_disko = var.stop_after_disko
      debug_logging = var.debug_logging
      kexec_tarball_url = var.kexec_tarball_url
      nixos_partitioner = var.nixos_partitioner
      nixos_system = var.nixos_system
      target_user = var.target_user
      target_host = var.target_host
      target_port = var.target_port
      extra_files_script = var.extra_files_script
      no_reboot = var.no_reboot
      build_on_remote = var.build_on_remote
      flake = var.flake
    }, var.extra_environment)
    command = "${path.module}/run-nixos-anywhere.sh ${join(" ", local.disk_encryption_key_scripts)}"
    quiet   = var.debug_logging
  }
}
