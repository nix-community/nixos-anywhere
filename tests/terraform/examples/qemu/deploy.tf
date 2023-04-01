data "local_file" "ssh-key" {
  filename = "${path.module}/../../../modules/ssh-keys/ssh"
}

module "deploy" {
  source                 = "../../../../terraform/all-in-one"
  file                   = "${path.module}"
  nixos_system_attr      = "system"
  nixos_partitioner_attr = "disko"
  target_host            = libvirt_domain.machine.network_interface.0.addresses[0]
  install_user = "nix"
  install_ssh_key        = data.local_file.ssh-key.content
  deployment_ssh_key     = data.local_file.ssh-key.content
  instance_id            = libvirt_domain.machine.id
  debug_logging          = true
}
