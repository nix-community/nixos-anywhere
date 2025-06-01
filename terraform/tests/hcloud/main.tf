terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
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

provider "hcloud" {
  token = var.hcloud_token
}

variable "hcloud_token" {
  description = "Hetzner Cloud API token (64 characters)"
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

# Create Hetzner Cloud SSH key
resource "hcloud_ssh_key" "test_key" {
  name       = "${var.test_name_prefix}-deployment-key"
  public_key = tls_private_key.test_key.public_key_openssh
}

# Create test server
resource "hcloud_server" "test_server" {
  name        = "${var.test_name_prefix}-server"
  image       = "ubuntu-22.04"
  server_type = "cx22"
  location    = "hel1"
  ssh_keys    = [hcloud_ssh_key.test_key.id]

  labels = {
    purpose  = "nixos-anywhere-test"
    test_run = replace(replace(replace(timestamp(), ":", "-"), "T", "-"), "Z", "")
  }
}

# nixos-anywhere all-in-one module
module "nixos_anywhere" {
  source = "../../all-in-one"

  nixos_system_attr      = var.nixos_system_attr
  nixos_partitioner_attr = var.nixos_partitioner_attr
  target_host            = hcloud_server.test_server.ipv4_address
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
