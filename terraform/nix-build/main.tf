locals {
  nix_options = jsonencode({
    options = { for k, v in var.nix_options : k => v }
  })
}
data "external" "nix-build" {
  program = ["${path.module}/nix-build.sh"]
  query = {
    attribute     = var.attribute
    file          = var.file
    nix_options   = local.nix_options
    debug_logging = var.debug_logging
    special_args  = jsonencode(var.special_args)
  }
}
output "result" {
  value = data.external.nix-build.result
}
