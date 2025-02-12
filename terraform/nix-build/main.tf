locals {
  nix_argstrs = jsonencode({
    argstrs = { for k, v in var.nix_argstrs : k => v }
  })
  nix_options = jsonencode({
    options = { for k, v in var.nix_options : k => v }
  })
}
data "external" "nix-build" {
  program = [ "${path.module}/nix-build.sh" ]
  query = {
    attribute = var.attribute
    file = var.file
    nix_argstrs = local.nix_argstrs
    nix_options = local.nix_options
    special_args = jsonencode(var.special_args)
  }
}
output "result" {
  value = data.external.nix-build.result
}
