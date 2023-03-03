locals {
  use_sudo = var.target_user != "root" ? "1" : "0"
}

resource "null_resource" "nixos-rebuild" {
  triggers = {
    store_path = var.nixos_system
  }
  provisioner "local-exec" {
    command = "${path.module}/deploy.sh ${var.nixos_system} ${var.target_user}@${var.target_host} ${var.target_port} ${local.use_sudo}"
  }
}
