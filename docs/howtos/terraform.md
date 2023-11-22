# Terraform

The nixos-anywhere terraform modules allow you to use Terraform for installing
and updating NixOS. It simplifies the deployment process by integrating
nixos-anywhere functionality.

Our terraform module requires the
[null](https://registry.terraform.io/providers/hashicorp/null/latest) and
[external](https://registry.terraform.io/providers/hashicorp/external/latest)
provider.

You can get these by from nixpkgs like this:

```nix
nix-shell -p '(pkgs.terraform.withPlugins (p: [ p.null p.external ]))'
```

You can add this expression the `packages` list in your devshell in flake.nix or
in shell.nix.

Checkout out the
[module reference](https://github.com/nix-community/nixos-anywhere/tree/main/terraform)
for examples and module parameter on how to use the modules.
