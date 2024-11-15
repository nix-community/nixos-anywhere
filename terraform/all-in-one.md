# All-in-one

Combines the install and nixos-rebuild module in one interface to install NixOS
with nixos-anywhere and then keep it up-to-date with nixos-rebuild.

## Example

```hcl
locals {
  ipv4 = "192.0.2.1"
}

module "deploy" {
  source                 = "github.com/nix-community/nixos-anywhere//terraform/all-in-one"
  # with flakes
  nixos_system_attr      = ".#nixosConfigurations.mymachine.config.system.build.toplevel"
  nixos_partitioner_attr = ".#nixosConfigurations.mymachine.config.system.build.diskoScript"
  # without flakes
  # file can use (pkgs.nixos []) function from nixpkgs
  #file                   = "${path.module}/../.."
  #nixos_system_attr      = "config.system.build.toplevel"
  #nixos_partitioner_attr = "config.system.build.diskoScript"

  target_host            = local.ipv4
  # when instance id changes, it will trigger a reinstall
  instance_id            = local.ipv4
  # useful if something goes wrong
  # debug_logging          = true
  # script is below
  extra_files_script     = "${path.module}/decrypt-ssh-secrets.sh"
  disk_encryption_key_scripts = [{
    path   = "/tmp/secret.key"
    # script is below
    script = "${path.module}/decrypt-zfs-key.sh"
  }]
}
```

_Note:_ You need to mark scripts as executable (`chmod +x`)

### ./decrypt-ssh-secrets.sh

```bash
#!/usr/bin/env bash

mkdir -p etc/ssh var/lib/secrets

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

umask 0177
sops --extract '["initrd_ssh_key"]' --decrypt "$SCRIPT_DIR/secrets.yaml" >./var/lib/secrets/initrd_ssh_key

# restore umask
umask 0022

for keyname in ssh_host_rsa_key ssh_host_rsa_key.pub ssh_host_ed25519_key ssh_host_ed25519_key.pub; do
  if [[ $keyname == *.pub ]]; then
    umask 0133
  else
    umask 0177
  fi
  sops --extract '["'$keyname'"]' --decrypt "$SCRIPT_DIR/secrets.yaml" >"./etc/ssh/$keyname"
done
```

### ./decrypt-zfs-key.sh

```bash
#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$SCRIPT_DIR"
sops --extract '["zfs-key"]' --decrypt "$SCRIPT_DIR/secrets.yaml"
```

## See also

- [nixos-wiki setup](https://github.com/NixOS/nixos-wiki-infra/blob/main/terraform/nixos-wiki/main.tf)
  for hetzner-cloud

<!-- BEGIN_TF_DOCS -->

## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name                                                                                   | Source           | Version |
| -------------------------------------------------------------------------------------- | ---------------- | ------- |
| <a name="module_install"></a> [install](#module_install)                               | ../install       | n/a     |
| <a name="module_nixos-rebuild"></a> [nixos-rebuild](#module_nixos-rebuild)             | ../nixos-rebuild | n/a     |
| <a name="module_partitioner-build"></a> [partitioner-build](#module_partitioner-build) | ../nix-build     | n/a     |
| <a name="module_system-build"></a> [system-build](#module_system-build)                | ../nix-build     | n/a     |

## Resources

No resources.

## Inputs

| Name                                                                                                                  | Description                                                                                                                                                                                                                                               | Type                                                                   | Default                                                                 | Required |
| --------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------- | ----------------------------------------------------------------------- | :------: |
| <a name="input_debug_logging"></a> [debug\_logging](#input_debug_logging)                                             | Enable debug logging                                                                                                                                                                                                                                      | `bool`                                                                 | `false`                                                                 |    no    |
| <a name="input_deployment_ssh_key"></a> [deployment\_ssh\_key](#input_deployment_ssh_key)                             | Content of private key used to deploy to the target\_host after initial installation. To ensure maximum security, it is advisable to connect to your host using ssh-agent instead of relying on this variable                                             | `string`                                                               | `null`                                                                  |    no    |
| <a name="input_disk_encryption_key_scripts"></a> [disk\_encryption\_key\_scripts](#input_disk_encryption_key_scripts) | Each script will be executed locally. Output of each will be created at the given path to disko during installation. The keys will be not copied to the final system                                                                                      | <pre>list(object({<br> path = string<br> script = string<br> }))</pre> | `[]`                                                                    |    no    |
| <a name="input_extra_environment"></a> [extra\_environment](#input_extra_environment)                                 | Extra environment variables to be set during installation. This can be useful to set extra variables for the extra\_files\_script or disk\_encryption\_key\_scripts                                                                                       | `map(string)`                                                          | `{}`                                                                    |    no    |
| <a name="input_extra_files_script"></a> [extra\_files\_script](#input_extra_files_script)                             | A script that should place files in the current directory that will be copied to the targets / directory                                                                                                                                                  | `string`                                                               | `null`                                                                  |    no    |
| <a name="input_file"></a> [file](#input_file)                                                                         | Nix file containing the nixos\_system\_attr and nixos\_partitioner\_attr. Use this if you are not using flake                                                                                                                                             | `string`                                                               | `null`                                                                  |    no    |
| <a name="input_install_port"></a> [install\_port](#input_install_port)                                                | SSH port used to connect to the target\_host, before installing NixOS. If null than the value of `target_port` is used                                                                                                                                    | `string`                                                               | `null`                                                                  |    no    |
| <a name="input_install_ssh_key"></a> [install\_ssh\_key](#input_install_ssh_key)                                      | Content of private key used to connect to the target\_host during initial installation                                                                                                                                                                    | `string`                                                               | `null`                                                                  |    no    |
| <a name="input_install_user"></a> [install\_user](#input_install_user)                                                | SSH user used to connect to the target\_host, before installing NixOS. If null than the value of `target_host` is used                                                                                                                                    | `string`                                                               | `null`                                                                  |    no    |
| <a name="input_instance_id"></a> [instance\_id](#input_instance_id)                                                   | The instance id of the target\_host, used to track when to reinstall the machine                                                                                                                                                                          | `string`                                                               | `null`                                                                  |    no    |
| <a name="input_kexec_tarball_url"></a> [kexec\_tarball\_url](#input_kexec_tarball_url)                                | NixOS kexec installer tarball url                                                                                                                                                                                                                         | `string`                                                               | `null`                                                                  |    no    |
| <a name="input_nix_options"></a> [nix\_options](#input_nix_options)                                                   | the options of nix                                                                                                                                                                                                                                        | `map(string)`                                                          | `{}`                                                                    |    no    |
| <a name="input_nixos_facter_path"></a> [nixos\_facter\_path](#input_nixos_facter_path)                                | Path to which to write a `facter.json` generated by `nixos-facter`.                                                                                                                                                                                       | `string`                                                               | `""`                                                                    |    no    |
| <a name="input_nixos_generate_config_path"></a> [nixos\_generate\_config\_path](#input_nixos_generate_config_path)    | Path to which to write a `hardware-configuration.nix` generated by `nixos-generate-config`.                                                                                                                                                               | `string`                                                               | `""`                                                                    |    no    |
| <a name="input_nixos_partitioner_attr"></a> [nixos\_partitioner\_attr](#input_nixos_partitioner_attr)                 | Nixos partitioner and mount script i.e. your-flake#nixosConfigurations.your-evaluated-nixos.config.system.build.diskoNoDeps or just your-evaluated.config.system.build.diskNoDeps. `config.system.build.diskNoDeps` is provided by the disko nixos module | `string`                                                               | n/a                                                                     |   yes    |
| <a name="input_nixos_system_attr"></a> [nixos\_system\_attr](#input_nixos_system_attr)                                | The nixos system to deploy i.e. your-flake#nixosConfigurations.your-evaluated-nixos.config.system.build.toplevel or just your-evaluated-nixos.config.system.build.toplevel if you are not using flakes                                                    | `string`                                                               | n/a                                                                     |   yes    |
| <a name="input_no_reboot"></a> [no\_reboot](#input_no_reboot)                                                         | DEPRECATED: Use `phases` instead. Do not reboot after installation                                                                                                                                                                                        | `bool`                                                                 | `false`                                                                 |    no    |
| <a name="input_phases"></a> [phases](#input_phases)                                                                   | Phases to run. See `nixos-anywhere --help` for more information                                                                                                                                                                                           | `set(string)`                                                          | <pre>[<br> "kexec",<br> "disko",<br> "install",<br> "reboot"<br>]</pre> |    no    |
| <a name="input_special_args"></a> [special\_args](#input_special_args)                                                | A map exposed as NixOS's `specialArgs` thru a file.                                                                                                                                                                                                       | `any`                                                                  | `{}`                                                                    |    no    |
| <a name="input_stop_after_disko"></a> [stop\_after\_disko](#input_stop_after_disko)                                   | DEPRECATED: Use `phases` instead. Exit after disko formatting                                                                                                                                                                                             | `bool`                                                                 | `false`                                                                 |    no    |
| <a name="input_target_host"></a> [target\_host](#input_target_host)                                                   | DNS host to deploy to                                                                                                                                                                                                                                     | `string`                                                               | n/a                                                                     |   yes    |
| <a name="input_target_port"></a> [target\_port](#input_target_port)                                                   | SSH port used to connect to the target\_host after installing NixOS. If install\_port is not set than this port is also used before installing.                                                                                                           | `number`                                                               | `22`                                                                    |    no    |
| <a name="input_target_user"></a> [target\_user](#input_target_user)                                                   | SSH user used to connect to the target\_host after installing NixOS. If install\_user is not set than this user is also used before installing.                                                                                                           | `string`                                                               | `"root"`                                                                |    no    |

## Outputs

| Name                                                  | Description |
| ----------------------------------------------------- | ----------- |
| <a name="output_result"></a> [result](#output_result) | n/a         |

<!-- END_TF_DOCS -->
