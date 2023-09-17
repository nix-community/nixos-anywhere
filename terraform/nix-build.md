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

| Name                                                         | Description                                        | Type     | Default | Required |
| ------------------------------------------------------------ | -------------------------------------------------- | -------- | ------- | :------: |
| <a name="input_attribute"></a> [attribute](#input_attribute) | the attribute to build, can also be a flake        | `string` | n/a     |   yes    |
| <a name="input_file"></a> [file](#input_file)                | the nix file to evaluate, if not run in flake mode | `string` | `null`  |    no    |

## Outputs

| Name                                                  | Description |
| ----------------------------------------------------- | ----------- |
| <a name="output_result"></a> [result](#output_result) | n/a         |

<!-- END_TF_DOCS -->
