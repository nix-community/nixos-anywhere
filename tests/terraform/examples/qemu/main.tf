resource "libvirt_pool" "ubuntu" {
  name = "ubuntu2"
  type = "dir"
  path = "/tmp/terraform-provider-libvirt-pool-ubuntu"
}

resource "libvirt_volume" "ubuntu-qcow2" {
  name   = "ubuntu-qcow2"
  pool   = libvirt_pool.ubuntu.name
  source = "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64-disk-kvm.img"
  format = "qcow2"
}

resource "libvirt_volume" "rootfs" {
  name = "rootfs"
  base_volume_id = libvirt_volume.ubuntu-qcow2.id
  size = "34359738368"
}

data "local_file" "ssh-public-key" {
  filename = "${path.module}/../../../modules/ssh-keys/ssh.pub"
}

resource "libvirt_cloudinit_disk" "commoninit" {
  name = "commoninit.iso"
  user_data = templatefile("${path.module}/cloud_init.cfg.tftpl", {
  ssh_public_key = data.local_file.ssh-public-key.content })
  network_config = yamlencode({
    version = 2
    ethernets = {
      ens3 = {
        dhcp4 = true
      }
    }
  })
  pool = libvirt_pool.ubuntu.name
}

resource "libvirt_domain" "machine" {
  name   = "ubuntu1"
  vcpu   = "2"
  memory = "4096"

  disk {
    volume_id = libvirt_volume.rootfs.id
  }

  graphics {
    listen_type = "address"
  }

  cloudinit = libvirt_cloudinit_disk.commoninit.id
  network_interface {
    network_name = "default"
    wait_for_lease = true
  }
}
