# When use_target_as_builder is enabled, we boot kexec first so target has nix,
# then either:
# 1. build_on_remote=true: nixos-anywhere builds directly on target (nix store preserved)
# 2. build_on_remote=false: local nix-build uses target as remote builder

locals {
  install_user = var.install_user == null ? var.target_user : var.install_user
  install_port = var.install_port == null ? var.target_port : var.install_port

  # Split phases: kexec runs separately when using target as builder
  remaining_phases   = setsubtract(var.phases, ["kexec"])
  should_kexec_first = var.use_target_as_builder && contains(var.phases, "kexec")

  # Extract flake URI from nixos_system_attr for build_on_remote mode
  # Input:  /path#nixosConfigurations.name.config.system.build.toplevel
  # Output: /path#name
  attr_parts   = var.file == null ? split("#", var.nixos_system_attr) : ["", ""]
  flake_path   = local.attr_parts[0]
  attr_path    = length(local.attr_parts) > 1 ? local.attr_parts[1] : ""
  config_parts = split(".", local.attr_path)
  config_name  = length(local.config_parts) > 1 ? local.config_parts[1] : ""
  flake_uri    = local.flake_path != "" && local.config_name != "" ? "${local.flake_path}#${local.config_name}" : ""

  # When using target as builder with build_on_remote, skip local nix-build
  skip_local_build = var.use_target_as_builder && var.build_on_remote && local.flake_uri != ""
}

# Boot kexec first if using target as builder (so target has nix available)
module "kexec-boot" {
  count  = local.should_kexec_first ? 1 : 0
  source = "../install"

  kexec_tarball_url = var.kexec_tarball_url
  target_user       = local.install_user
  target_host       = var.target_host
  target_port       = local.install_port
  ssh_private_key   = var.install_ssh_key
  debug_logging     = var.debug_logging
  extra_environment = var.extra_environment
  instance_id       = "${var.instance_id}-kexec"
  phases            = ["kexec"]
  flake             = local.flake_uri
  copy_host_keys    = var.copy_host_keys
}

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

module "install" {
  depends_on = [module.kexec-boot]
  source     = "../install"

  kexec_tarball_url           = var.kexec_tarball_url
  target_user                 = local.install_user
  target_host                 = var.target_host
  target_port                 = local.install_port
  nixos_partitioner           = join("", module.partitioner-build[*].result.out)
  nixos_system                = join("", module.system-build[*].result.out)
  flake                       = local.skip_local_build ? local.flake_uri : ""
  ssh_private_key             = var.install_ssh_key
  debug_logging               = var.debug_logging
  extra_files_script          = var.extra_files_script
  disk_encryption_key_scripts = var.disk_encryption_key_scripts
  extra_environment           = var.extra_environment
  instance_id                 = var.instance_id
  phases                      = var.use_target_as_builder ? local.remaining_phases : var.phases
  nixos_generate_config_path  = var.nixos_generate_config_path
  nixos_facter_path           = var.nixos_facter_path
  build_on_remote             = local.skip_local_build ? true : var.build_on_remote
  copy_host_keys              = var.use_target_as_builder ? false : var.copy_host_keys
  # deprecated attributes
  stop_after_disko            = var.stop_after_disko
  no_reboot                   = var.no_reboot
}

module "nixos-rebuild" {
  depends_on = [module.install]

  # Skip when stop_after_disko or when build_on_remote handles the full install
  count = var.stop_after_disko || local.skip_local_build ? 0 : 1

  source             = "../nixos-rebuild"
  nixos_system       = module.system-build[0].result.out
  ssh_private_key    = var.deployment_ssh_key
  target_host        = var.target_host
  target_user        = var.target_user
  target_port        = var.target_port
  install_bootloader = var.install_bootloader
}

output "result" {
  value = length(module.system-build) > 0 ? module.system-build[0].result : { out = "" }
}
