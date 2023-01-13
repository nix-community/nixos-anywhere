resource "null_resource" "nixos-remote" {
  provisioner "local-exec" {
    environment = {
      SSH_PRIVATE_KEY = var.ssh_private_key
    }
    command = "nix run ${path.module}#nixos-remote -- --store-paths ${var.nixos_partitioner} ${var.nixos_system} ${var.target_user}@${var.target_host}"
  }
}
