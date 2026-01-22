# When use_target_as_builder is enabled, we boot kexec first so target has nix,
# then either:
# 1. build_on_remote=true: nixos-anywhere builds directly on target (nix store preserved)
# 2. build_on_remote=false: local nix-build uses target as remote builder

locals {
  install_user = var.install_user == null ? var.target_user : var.install_user
  install_port = var.install_port == null ? var.target_port : var.install_port

  # Split phases: kexec runs first if using target as builder
  has_kexec_phase    = contains(var.phases, "kexec")
  remaining_phases   = toset([for p in var.phases : p if p != "kexec"])
  should_kexec_first = var.use_target_as_builder && local.has_kexec_phase

  # Extract flake URI from nixos_system_attr for build_on_remote mode
  # Input:  /path#nixosConfigurations.name.config.system.build.toplevel
  # Output: /path#name
  attr_parts     = var.file == null ? split("#", var.nixos_system_attr) : ["", ""]
  flake_path     = local.attr_parts[0]
  attr_path      = length(local.attr_parts) > 1 ? local.attr_parts[1] : ""
  # Extract config name: nixosConfigurations.NAME.config... -> NAME
  config_parts   = split(".", local.attr_path)
  config_name    = length(local.config_parts) > 1 ? local.config_parts[1] : ""
  flake_uri      = local.flake_path != "" && local.config_name != "" ? "${local.flake_path}#${local.config_name}" : ""

  # When using target as builder with build_on_remote, skip local nix-build
  skip_local_build = var.use_target_as_builder && var.build_on_remote && local.flake_uri != ""
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

# Step 2: Build system locally (skipped when build_on_remote=true with flake)
module "system-build" {
  count      = local.skip_local_build ? 0 : 1
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
  count      = local.skip_local_build ? 0 : 1
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

# Step 3a: Full install - local build mode (original flow, use_target_as_builder=false)
module "install" {
  count = !var.use_target_as_builder ? 1 : 0

  source                      = "../install"
  kexec_tarball_url           = var.kexec_tarball_url
  target_user                 = local.install_user
  target_host                 = var.target_host
  target_port                 = local.install_port
  nixos_partitioner           = module.partitioner-build[0].result.out
  nixos_system                = module.system-build[0].result.out
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
  stop_after_disko            = var.stop_after_disko
  no_reboot                   = var.no_reboot
}

# Step 3b: Install with remote build - builds on kexec'd target, nix store preserved
module "install-remote-build" {
  count      = local.skip_local_build ? 1 : 0
  depends_on = [module.kexec-boot]

  source                      = "../install"
  kexec_tarball_url           = var.kexec_tarball_url
  target_user                 = local.install_user
  target_host                 = var.target_host
  target_port                 = local.install_port
  flake                       = local.flake_uri
  ssh_private_key             = var.install_ssh_key
  debug_logging               = var.debug_logging
  extra_files_script          = var.extra_files_script
  disk_encryption_key_scripts = var.disk_encryption_key_scripts
  extra_environment           = var.extra_environment
  instance_id                 = var.instance_id
  phases                      = local.remaining_phases
  nixos_generate_config_path  = var.nixos_generate_config_path
  nixos_facter_path           = var.nixos_facter_path
  build_on_remote             = true
  copy_host_keys              = false # Already copied in kexec-boot
  stop_after_disko            = var.stop_after_disko
  no_reboot                   = var.no_reboot
}

# Step 3c: Install after kexec - local build with remote builder (nix store NOT preserved)
module "install-after-kexec" {
  count = var.use_target_as_builder && !var.build_on_remote ? 1 : 0

  source                      = "../install"
  kexec_tarball_url           = var.kexec_tarball_url
  target_user                 = local.install_user
  target_host                 = var.target_host
  target_port                 = local.install_port
  nixos_partitioner           = module.partitioner-build[0].result.out
  nixos_system                = module.system-build[0].result.out
  ssh_private_key             = var.install_ssh_key
  debug_logging               = var.debug_logging
  extra_files_script          = var.extra_files_script
  disk_encryption_key_scripts = var.disk_encryption_key_scripts
  extra_environment           = var.extra_environment
  instance_id                 = var.instance_id
  phases                      = local.remaining_phases
  nixos_generate_config_path  = var.nixos_generate_config_path
  nixos_facter_path           = var.nixos_facter_path
  build_on_remote             = false
  copy_host_keys              = false # Already copied in kexec-boot
  stop_after_disko            = var.stop_after_disko
  no_reboot                   = var.no_reboot
}

module "nixos-rebuild" {
  depends_on = [
    module.install,
    module.install-remote-build,
    module.install-after-kexec
  ]

  # Do not execute this step if var.stop_after_disko == true
  count = var.stop_after_disko ? 0 : 1

  source             = "../nixos-rebuild"
  nixos_system       = local.skip_local_build ? "" : module.system-build[0].result.out
  ssh_private_key    = var.deployment_ssh_key
  target_host        = var.target_host
  target_user        = var.target_user
  target_port        = var.target_port
  install_bootloader = var.install_bootloader
}

output "result" {
  value = local.skip_local_build ? { out = "" } : module.system-build[0].result
}
