module "system-build" {
  source                = "../nix-build"
  attribute             = var.nixos_system_attr
  debug_logging         = var.debug_logging
  file                  = var.file
  nix_options           = var.nix_options
  special_args          = var.special_args
  target_host           = var.target_host
  target_user           = var.install_user != null ? var.install_user : var.target_user
  target_port           = var.install_port != null ? var.install_port : var.target_port
  use_target_as_builder = var.use_target_as_builder
}

module "partitioner-build" {
  source                = "../nix-build"
  attribute             = var.nixos_partitioner_attr
  debug_logging         = var.debug_logging
  file                  = var.file
  nix_options           = var.nix_options
  special_args          = var.special_args
  target_host           = var.target_host
  target_user           = var.install_user != null ? var.install_user : var.target_user
  target_port           = var.install_port != null ? var.install_port : var.target_port
  use_target_as_builder = var.use_target_as_builder
}

locals {
  install_user = var.install_user == null ? var.target_user : var.install_user
  install_port = var.install_port == null ? var.target_port : var.install_port
}

module "install" {
  source                      = "../install"
  kexec_tarball_url           = var.kexec_tarball_url
  target_user                 = local.install_user
  target_host                 = var.target_host
  target_port                 = local.install_port
  nixos_partitioner           = module.partitioner-build.result.out
  nixos_system                = module.system-build.result.out
  ssh_private_key             = var.install_ssh_key
  debug_logging               = var.debug_logging
  extra_files_script          = var.extra_files_script
  disk_encryption_key_scripts = var.disk_encryption_key_scripts
  extra_environment           = var.extra_environment
  instance_id                 = var.instance_id
  phases                      = var.phases
  nixos_generate_config_path  = var.nixos_generate_config_path
  nixos_facter_path           = var.nixos_facter_path
  build_on_remote             = var.build_on_remote
  copy_host_keys              = var.copy_host_keys
  # deprecated attributes
  stop_after_disko = var.stop_after_disko
  no_reboot        = var.no_reboot
}

module "nixos-rebuild" {
  depends_on = [
    module.install
  ]

  # Do not execute this step if var.stop_after_disko == true
  count = var.stop_after_disko ? 0 : 1

  source             = "../nixos-rebuild"
  nixos_system       = module.system-build.result.out
  ssh_private_key    = var.deployment_ssh_key
  target_host        = var.target_host
  target_user        = var.target_user
  target_port        = var.target_port
  install_bootloader = var.install_bootloader
}

output "result" {
  value = module.system-build.result
}
