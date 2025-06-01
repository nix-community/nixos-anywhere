terraform {
  required_providers {
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

variable "nixos_system_attr" {
  description = "NixOS system attribute to deploy"
  type        = string
  default     = ""
}

variable "nixos_partitioner_attr" {
  description = "NixOS partitioner attribute"
  type        = string
  default     = ""
}

variable "target_host" {
  description = "Target host for deployment"
  type        = string
  default     = "test.example.com"
}

variable "target_port" {
  description = "Target SSH port"
  type        = number
  default     = 22
}

variable "target_user" {
  description = "Target SSH user"
  type        = string
  default     = "root"
}

variable "debug_logging" {
  description = "Enable debug logging"
  type        = bool
  default     = false
}

variable "phases" {
  description = "Deployment phases to run"
  type        = set(string)
  default     = ["kexec", "disko", "install"]
}

variable "build_on_remote" {
  description = "Build on remote machine"
  type        = bool
  default     = false
}

variable "install_ssh_key" {
  description = "SSH private key for installation"
  type        = string
  default     = ""
  sensitive   = true
}

# nixos-anywhere all-in-one module
module "nixos_anywhere" {
  source = "../all-in-one"

  nixos_system_attr      = var.nixos_system_attr
  nixos_partitioner_attr = var.nixos_partitioner_attr
  target_host            = var.target_host
  target_port            = var.target_port
  target_user            = var.target_user
  debug_logging          = var.debug_logging
  phases                 = var.phases
  build_on_remote        = var.build_on_remote
  install_ssh_key        = var.install_ssh_key
}

output "nixos_anywhere_result" {
  description = "nixos-anywhere module result"
  value       = module.nixos_anywhere.result
}
