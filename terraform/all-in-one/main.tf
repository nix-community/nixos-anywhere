# When use_target_as_builder is enabled, we need to boot kexec first
# so the target has nix available for remote building

locals {
  install_user = var.install_user == null ? var.target_user : var.install_user
  install_port = var.install_port == null ? var.target_port : var.install_port

  # Split phases: kexec runs first if using target as builder
  has_kexec_phase    = contains(var.phases, "kexec")
  remaining_phases   = toset([for p in var.phases : p if p != "kexec"])
  should_kexec_first = var.use_target_as_builder && local.has_kexec_phase
}

# Step 1: Boot kexec first if using target as builder (so target has nix available)
module "kexec-boot" {
  count  = local.should_kexec_first ? 1 : 0
  source = "../install"

  kexec_tarball_url           = var.kexec_tarball_url
  target_user                 = local.install_user
  target_host                 = var.target_host
  target_port                 = local.install_port
  ssh_private_key             = var.install_ssh_key
  debug_logging               = var.debug_logging
  extra_environment           = var.extra_environment
  instance_id                 = "${var.instance_id}-kexec"
  phases                      = ["kexec"]
  build_on_remote             = false
  copy_host_keys              = var.copy_host_keys
  extra_files_script          = null
  disk_encryption_key_scripts = []
  nixos_generate_config_path  = ""
  nixos_facter_path           = ""
  stop_after_disko            = false
  no_reboot                   = false
}

# Step 2: Build system (uses target as builder if kexec'd, otherwise builds locally)
module "system-build" {
  depends_on = [module.kexec-boot]

  source                = "../nix-build"
  attribute             = var.nixos_system_attr
  debug_logging         = var.debug_logging
  file                  = var.file
  nix_options           = var.nix_options
  special_args          = var.special_args
  target_host           = var.target_host
  target_user           = local.install_user
  target_port           = local.install_port
  use_target_as_builder = var.use_target_as_builder
}

module "partitioner-build" {
  depends_on = [module.kexec-boot]

  source                = "../nix-build"
  attribute             = var.nixos_partitioner_attr
  debug_logging         = var.debug_logging
  file                  = var.file
  nix_options           = var.nix_options
  special_args          = var.special_args
  target_host           = var.target_host
  target_user           = local.install_user
  target_port           = local.install_port
  use_target_as_builder = var.use_target_as_builder
}

# Step 3a: Full install (when NOT using target as builder - original flow)
module "install" {
  count = local.should_kexec_first ? 0 : 1

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

# Step 3b: Continue install after kexec (when using target as builder)
module "install-after-kexec" {
  count = local.should_kexec_first ? 1 : 0

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
  phases                      = local.remaining_phases
  nixos_generate_config_path  = var.nixos_generate_config_path
  nixos_facter_path           = var.nixos_facter_path
  build_on_remote             = var.build_on_remote
  copy_host_keys              = false # Already copied in kexec-boot
  # deprecated attributes
  stop_after_disko = var.stop_after_disko
  no_reboot        = var.no_reboot
}

module "nixos-rebuild" {
  depends_on = [
    module.install,
    module.install-after-kexec
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
