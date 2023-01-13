resource "null_resource" "nixos-rebuild" {
  triggers = {
    store_path = var.nixos_system
  }
  provisioner "local-exec" {
    command = "${path.module}/deploy.sh ${var.nixos_system} root@${var.target_host} ${var.target_port}"
  }
}
