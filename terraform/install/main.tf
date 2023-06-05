locals {
  nixos_anywhere_flags = "${var.stop_after_disko ? "--stop-after-disko" : ""} ${var.debug_logging ? "--debug" : ""} ${var.kexec_tarball_url != null ? "--kexec ${var.kexec_tarball_url}" : "" } --store-paths ${var.nixos_partitioner} ${var.nixos_system} ${var.target_user}@${var.target_host}"
}

resource "null_resource" "nixos-remote" {
  triggers = {
    instance_id = var.instance_id
  }
  provisioner "local-exec" {
    environment = {
      SSH_PRIVATE_KEY = var.ssh_private_key
    }
    command = "nix run --extra-experimental-features 'nix-command flakes' path:${path.module}/../..#nixos-anywhere -- ${local.nixos_anywhere_flags}"
    quiet   = var.debug_logging
  }
}
