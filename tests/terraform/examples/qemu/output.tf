output "ipv4" {
  value = libvirt_domain.machine.network_interface.0.addresses
}
