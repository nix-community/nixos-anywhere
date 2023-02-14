variable "kexec_tarball_url" {
  type = string
  description = "NixOS kexec installer tarball url"
  default = null
}

# To make this re-usuable we maybe should accept a store path here?
variable "nixos_partitioner_attr" {
  type        = string
  description = "nixos partitioner and mount script"
}

# To make this re-usuable we maybe should accept a store path here?
variable "nixos_system_attr" {
  type        = string
  description = "The nixos system to deploy"
}

variable "file" {
  type        = string
  description = "file to get the nixos_system_attr and nixos_partitioner_attr from if they are not flakes."
  default     = null
}

variable "target_host" {
  type        = string
  description = "DNS host to deploy to"
}

variable "target_user" {
  type        = string
  description = "SSH user used to connect to the target_host, before installing NixOS"
  default     = "root"
}

variable "target_port" {
  type        = number
  description = "SSH port used to connect to the target_host, before installing NixOS"
  default     = 22
}

variable "ssh_private_key" {
  type        = string
  description = "Content of private key used to connect to the target_host"
  default     = null
}
