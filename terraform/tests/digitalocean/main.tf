terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.34"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

provider "digitalocean" {
  token = var.digitalocean_token
}

variable "digitalocean_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "test_name_prefix" {
  description = "Prefix for test resource names"
  type        = string
  default     = "tftest-nixos-anywhere"
}

variable "nixos_system_attr" {
  description = "NixOS system attribute to deploy"
  type        = string
}

variable "nixos_partitioner_attr" {
  description = "NixOS partitioner attribute"
  type        = string
}

variable "debug_logging" {
  description = "Enable debug logging"
  type        = bool
  default     = false
}

# Generate SSH key pair
resource "tls_private_key" "test_key" {
  algorithm = "ED25519"
}

# Save private key to file
resource "local_file" "private_key" {
  content         = tls_private_key.test_key.private_key_openssh
  filename        = "${path.root}/test_key"
  file_permission = "0600"
}

# Save public key to file
resource "local_file" "public_key" {
  content  = tls_private_key.test_key.public_key_openssh
  filename = "${path.root}/test_key.pub"
}

# Create DigitalOcean SSH key
resource "digitalocean_ssh_key" "test_key" {
  name       = "${var.test_name_prefix}-deployment-key"
  public_key = tls_private_key.test_key.public_key_openssh
}

# Create test droplet
# Note: Using s-2vcpu-2gb (minimum 2GB RAM required for nixos-anywhere kexec)
# DigitalOcean uses /dev/vda for disk devices (handled by digitalocean config)
resource "digitalocean_droplet" "test_server" {
  name     = "${var.test_name_prefix}-server"
  image    = "ubuntu-22-04-x64"
  size     = "s-2vcpu-2gb"
  region   = "nyc3"
  ssh_keys = [digitalocean_ssh_key.test_key.id]

  tags = [
    "nixos-anywhere-test",
    replace(replace(replace(timestamp(), ":", "-"), "T", "-"), "Z", "")
  ]
}

# nixos-anywhere all-in-one module
# Uses digitalocean configuration from nixos-anywhere-examples which:
# - Sets disk device to /dev/vda (DigitalOcean standard)
# - Configures cloud-init for network setup
# - Disables DHCP in favor of cloud-init provisioning
module "nixos_anywhere" {
  source = "../../all-in-one"

  nixos_system_attr      = var.nixos_system_attr
  nixos_partitioner_attr = var.nixos_partitioner_attr
  target_host            = digitalocean_droplet.test_server.ipv4_address
  target_port            = 22
  target_user            = "root"
  debug_logging          = var.debug_logging
  deployment_ssh_key     = tls_private_key.test_key.private_key_openssh
  install_ssh_key        = tls_private_key.test_key.private_key_openssh

  special_args = {
    extraPublicKeys = [tls_private_key.test_key.public_key_openssh]
  }
}

output "nixos_anywhere_result" {
  description = "nixos-anywhere module result"
  value       = module.nixos_anywhere.result
}

output "droplet_ip" {
  description = "DigitalOcean droplet public IP address"
  value       = digitalocean_droplet.test_server.ipv4_address
}

output "droplet_id" {
  description = "DigitalOcean droplet ID for cleanup"
  value       = digitalocean_droplet.test_server.id
}

output "ssh_key_id" {
  description = "DigitalOcean SSH key ID for cleanup"
  value       = digitalocean_ssh_key.test_key.id
}

output "ssh_connection_command" {
  description = "SSH command to connect to the deployed server"
  value       = "ssh -i ${local_file.private_key.filename} root@${digitalocean_droplet.test_server.ipv4_address}"
}