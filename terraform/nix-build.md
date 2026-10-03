# Nix-build

Small helper module to run do build a flake attribute or attribute from a nix
file.

## Example

- See [install](install.md) or [nixos-rebuild](nixos-rebuild.md)

<!-- BEGIN_TF_DOCS -->

## Requirements

No requirements.

## Providers

| Name                                                            | Version |
| --------------------------------------------------------------- | ------- |
| <a name="provider_external"></a> [external](#provider_external) | n/a     |

## Modules

No modules.

## Resources

| Name                                                                                                                        | Type        |
| --------------------------------------------------------------------------------------------------------------------------- | ----------- |
| [external_external.nix-build](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |

## Inputs

| Name                                                                      | Description                                         | Type          | Default | Required |
| ------------------------------------------------------------------------- | --------------------------------------------------- | ------------- | ------- | :------: |
| <a name="input_attribute"></a> [attribute](#input_attribute)              | the attribute to build, can also be a flake         | `string`      | n/a     |   yes    |
| <a name="input_debug_logging"></a> [debug\_logging](#input_debug_logging) | Enable debug logging                                | `bool`        | `false` |    no    |
| <a name="input_file"></a> [file](#input_file)                             | the nix file to evaluate, if not run in flake mode  | `string`      | `null`  |    no    |
| <a name="input_nix_options"></a> [nix\_options](#input_nix_options)       | the options of nix                                  | `map(string)` | `{}`    |    no    |
| <a name="input_special_args"></a> [special\_args](#input_special_args)    | A map exposed as NixOS's `specialArgs` thru a file. | `any`         | `{}`    |    no    |
| <a name="input_target_host"></a> [target\_host](#input_target_host)       | Target host to potentially use as remote builder    | `string`      | `null`  |    no    |
| <a name="input_target_user"></a> [target\_user](#input_target_user)       | SSH user for target host                            | `string`      | `"root"`|    no    |
| <a name="input_target_port"></a> [target\_port](#input_target_port)       | SSH port for target host                            | `number`      | `22`    |    no    |
| <a name="input_use_target_as_builder"></a> [use\_target\_as\_builder](#input_use_target_as_builder) | Use target host as remote nix builder if it has nix available | `bool` | `false` | no |

## Outputs

| Name                                                  | Description |
| ----------------------------------------------------- | ----------- |
| <a name="output_result"></a> [result](#output_result) | n/a         |

<!-- END_TF_DOCS -->
