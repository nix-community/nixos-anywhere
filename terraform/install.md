# Install

Install NixOS with nixos-anywhere

## Example

```hcl
locals {
  ipv4 = "192.0.2.1"
}

module "system-build" {
  source            = "github.com/nix-community/nixos-anywhere//terraform/nix-build"
  # with flakes
  attribute         = ".#nixosConfigurations.mymachine.config.system.build.toplevel"
  # without flakes
  # file can use (pkgs.nixos []) function from nixpkgs
  #file              = "${path.module}/../.."
  #attribute         = "config.system.build.toplevel"
}

module "disko" {
  source         = "github.com/nix-community/nixos-anywhere//terraform/nix-build"
  # with flakes
  attribute      = ".#nixosConfigurations.mymachine.config.system.build.diskoScript"
  # without flakes
  # file can use (pkgs.nixos []) function from nixpkgs
  #file           = "${path.module}/../.."
  #attribute      = "config.system.build.diskoScript"
}

module "install" {
  source            = "github.com/nix-community/nixos-anywhere//terraform/install"
  nixos_system      = module.system-build.result.out
  nixos_partitioner = module.disko.result.out
  target_host       = local.ipv4
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

| Name                                                                                                                | Type     |
| ------------------------------------------------------------------------------------------------------------------- | -------- |
| [null_resource.nixos-remote](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |

## Inputs

| Name                                                                                                                  | Description                                                                                                                                                          | Type                                                                      | Default                                                                      | Required |
| --------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------- | ---------------------------------------------------------------------------- | :------: |
| <a name="input_build_on_remote"></a> [build\_on\_remote](#input_build_on_remote)                                      | Build the closure on the remote machine instead of building it locally and copying it over                                                                           | `bool`                                                                    | `false`                                                                      |    no    |
| <a name="input_debug_logging"></a> [debug\_logging](#input_debug_logging)                                             | Enable debug logging                                                                                                                                                 | `bool`                                                                    | `false`                                                                      |    no    |
| <a name="input_disk_encryption_key_scripts"></a> [disk\_encryption\_key\_scripts](#input_disk_encryption_key_scripts) | Each script will be executed locally. Output of each will be created at the given path to disko during installation. The keys will be not copied to the final system | <pre>list(object({<br/> path = string<br/> script = string<br/> }))</pre> | `[]`                                                                         |    no    |
| <a name="input_extra_environment"></a> [extra\_environment](#input_extra_environment)                                 | Extra environment variables to be set during installation. This can be useful to set extra variables for the extra\_files\_script or disk\_encryption\_key\_scripts  | `map(string)`                                                             | `{}`                                                                         |    no    |
| <a name="input_extra_files_script"></a> [extra\_files\_script](#input_extra_files_script)                             | A script that should place files in the current directory that will be copied to the targets / directory                                                             | `string`                                                                  | `null`                                                                       |    no    |
| <a name="input_flake"></a> [flake](#input_flake)                                                                      | The flake to install the system from                                                                                                                                 | `string`                                                                  | `""`                                                                         |    no    |
| <a name="input_instance_id"></a> [instance\_id](#input_instance_id)                                                   | The instance id of the target\_host, used to track when to reinstall the machine                                                                                     | `string`                                                                  | `null`                                                                       |    no    |
| <a name="input_kexec_tarball_url"></a> [kexec\_tarball\_url](#input_kexec_tarball_url)                                | NixOS kexec installer tarball url                                                                                                                                    | `string`                                                                  | `null`                                                                       |    no    |
| <a name="input_nixos_facter_path"></a> [nixos\_facter\_path](#input_nixos_facter_path)                                | Path to which to write a `facter.json` generated by `nixos-facter`. This option cannot be set at the same time as `nixos_generate_config_path`.                      | `string`                                                                  | `""`                                                                         |    no    |
| <a name="input_nixos_generate_config_path"></a> [nixos\_generate\_config\_path](#input_nixos_generate_config_path)    | Path to which to write a `hardware-configuration.nix` generated by `nixos-generate-config`. This option cannot be set at the same time as `nixos_facter_path`.       | `string`                                                                  | `""`                                                                         |    no    |
| <a name="input_nixos_partitioner"></a> [nixos\_partitioner](#input_nixos_partitioner)                                 | nixos partitioner and mount script                                                                                                                                   | `string`                                                                  | `""`                                                                         |    no    |
| <a name="input_nixos_system"></a> [nixos\_system](#input_nixos_system)                                                | The nixos system to deploy                                                                                                                                           | `string`                                                                  | `""`                                                                         |    no    |
| <a name="input_no_reboot"></a> [no\_reboot](#input_no_reboot)                                                         | DEPRECATED: Use `phases` instead. Do not reboot after installation                                                                                                   | `bool`                                                                    | `false`                                                                      |    no    |
| <a name="input_phases"></a> [phases](#input_phases)                                                                   | Phases to run. See `nixos-anywhere --help` for more information                                                                                                      | `list(string)`                                                            | <pre>[<br/> "kexec",<br/> "disko",<br/> "install",<br/> "reboot"<br/>]</pre> |    no    |
| <a name="input_ssh_private_key"></a> [ssh\_private\_key](#input_ssh_private_key)                                      | Content of private key used to connect to the target\_host                                                                                                           | `string`                                                                  | `""`                                                                         |    no    |
| <a name="input_stop_after_disko"></a> [stop\_after\_disko](#input_stop_after_disko)                                   | DEPRECATED: Use `phases` instead. Exit after disko formatting                                                                                                        | `bool`                                                                    | `false`                                                                      |    no    |
| <a name="input_target_host"></a> [target\_host](#input_target_host)                                                   | DNS host to deploy to                                                                                                                                                | `string`                                                                  | n/a                                                                          |   yes    |
| <a name="input_target_pass"></a> [target\_pass](#input_target_pass)                                                   | Password used to connect to the target\_host                                                                                                                         | `string`                                                                  | `null`                                                                       |    no    |
| <a name="input_target_port"></a> [target\_port](#input_target_port)                                                   | SSH port used to connect to the target\_host                                                                                                                         | `number`                                                                  | `22`                                                                         |    no    |
| <a name="input_target_user"></a> [target\_user](#input_target_user)                                                   | SSH user used to connect to the target\_host                                                                                                                         | `string`                                                                  | `"root"`                                                                     |    no    |

## Outputs

No outputs.

<!-- END_TF_DOCS -->
