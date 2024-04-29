module "system-build" {
  source = "../nix-build"
  attribute = var.nixos_system_attr
  file = var.file
}

module "partitioner-build" {
  source = "../nix-build"
  attribute = var.nixos_partitioner_attr
  file = var.file
}

locals {
  install_user = var.install_user == null ? var.target_user : var.install_user
}

module "install" {
  source                       = "../install"
  kexec_tarball_url            = var.kexec_tarball_url
  target_user                  = local.install_user
  target_host                  = var.target_host
  target_port                  = var.target_port
  nixos_partitioner            = module.partitioner-build.result.out
  nixos_system                 = module.system-build.result.out
  ssh_private_key              = var.install_ssh_key
  debug_logging                = var.debug_logging
  stop_after_disko             = var.stop_after_disko
  extra_files_script           = var.extra_files_script
  disk_encryption_key_scripts  = var.disk_encryption_key_scripts
  extra_environment            = var.extra_environment
  instance_id                  = var.instance_id
  no_reboot                    = var.no_reboot
}

module "nixos-rebuild" {
  depends_on = [
    module.install
  ]

  # Do not execute this step if var.stop_after_disko == true  
  count = var.stop_after_disko ? 0 : 1

  source = "../nixos-rebuild"
  nixos_system = module.system-build.result.out
  ssh_private_key = var.deployment_ssh_key
  target_host = var.target_host
  target_user = var.target_user
  target_port = var.target_port
}

output "result" {
  value = module.system-build.result
}
