locals {
  nix_options = jsonencode({
    options = { for k, v in var.nix_options : k => v }
  })
}
data "external" "nix-build" {
  program = [ "${path.module}/nix-build.sh" ]
  query = {
    attribute = var.attribute
    file = var.file
    nix_options = local.nix_options
    environment = jsonencode(var.extra_build_env_vars)
  }
}
output "result" {
  value = data.external.nix-build.result
}
