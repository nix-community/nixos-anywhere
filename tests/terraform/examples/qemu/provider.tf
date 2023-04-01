terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
    }
    local = { source = "hashicorp/local" }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}
