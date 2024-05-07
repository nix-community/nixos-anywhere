locals {
  nix_options = var.nix_options == null ? "" : join(" ", [for k, v in var.nix_options :  "--option ${k} ${v}"])
}
data "external" "nix-build" {
  program = [ "${path.module}/nix-build.sh" ]
  query = {
    attribute = var.attribute
    file = var.file
    nix_options = local.nix_options
  }
}
output "result" {
  value = data.external.nix-build.result
}
