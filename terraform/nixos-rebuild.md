# Nixos-rebuild

Update NixOS machine with nixos-rebuild on a remote machine

## Example

```hcl
locals {
  ipv4 = "192.0.2.1"
}

module "system-build" {
  source              = "github.com/nix-community/nixos-anywhere//terraform/nix-build"
  # with flakes
  attribute           = ".#nixosConfigurations.mymachine.config.system.build.toplevel"
  # without flakes
  # file can use (pkgs.nixos []) function from nixpkgs
  #file                = "${path.module}/../.."
  #attribute           = "config.system.build.toplevel"
}

module "deploy" {
  source       = "github.com/nix-community/nixos-anywhere//terraform/nixos-rebuild"
  nixos_system = module.system-build.result.out
  target_host  = local.ipv4
}
```

<!-- BEGIN_TF_DOCS -->

## Requirements

No requirements.

## Providers

| Name                                                | Version |
| --------------------------------------------------- | ------- |
| <a name="provider_null"></a> [null](#provider_null) | n/a     |

## Modules

No modules.

## Resources

| Name                                                                                                                 | Type     |
| -------------------------------------------------------------------------------------------------------------------- | -------- |
| [null_resource.nixos-rebuild](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |

## Inputs

| Name                                                                                               | Description                                                                                                                                | Type     | Default  | Required |
| -------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ | -------- | -------- | :------: |
| <a name="input_ignore_systemd_errors"></a> [ignore\_systemd\_errors](#input_ignore_systemd_errors) | Ignore systemd errors happening during deploy                                                                                              | `bool`   | `false`  |    no    |
| <a name="input_install_bootloader"></a> [install\_bootloader](#input_install_bootloader)           | Install/re-install the bootloader                                                                                                          | `bool`   | `false`  |    no    |
| <a name="input_nixos_system"></a> [nixos\_system](#input_nixos_system)                             | The nixos system to deploy                                                                                                                 | `string` | n/a      |   yes    |
| <a name="input_ssh_private_key"></a> [ssh\_private\_key](#input_ssh_private_key)                   | Content of private key used to connect to the target\_host. If set to - no key is passed to openssh and ssh will use its own configuration | `string` | `"-"`    |    no    |
| <a name="input_target_host"></a> [target\_host](#input_target_host)                                | DNS host to deploy to                                                                                                                      | `string` | n/a      |   yes    |
| <a name="input_target_port"></a> [target\_port](#input_target_port)                                | SSH port used to connect to the target\_host                                                                                               | `number` | `22`     |    no    |
| <a name="input_target_user"></a> [target\_user](#input_target_user)                                | User to deploy as                                                                                                                          | `string` | `"root"` |    no    |

## Outputs

No outputs.

<!-- END_TF_DOCS -->
