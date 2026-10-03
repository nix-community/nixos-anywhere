locals {
  nix_options = jsonencode({
    options = { for k, v in var.nix_options : k => v }
  })
}
data "external" "nix-build" {
  program = ["${path.module}/nix-build.sh"]
  query = {
    attribute             = var.attribute
    file                  = var.file
    nix_options           = local.nix_options
    debug_logging         = var.debug_logging
    special_args          = jsonencode(var.special_args)
    target_host           = var.target_host
    target_user           = var.target_user
    target_port           = var.target_port
    use_target_as_builder = var.use_target_as_builder
  }
}
output "result" {
  value = data.external.nix-build.result
}
