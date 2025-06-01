variable "nixos_system" {
  type        = string
  description = "The nixos system to deploy"
}

variable "target_host" {
  type        = string
  description = "DNS host to deploy to"
}

variable "target_user" {
  type        = string
  default     = "root"
  description = "User to deploy as"
}

variable "target_port" {
  type        = number
  description = "SSH port used to connect to the target_host"
  default     = 22
}

variable "ssh_private_key" {
  type        = string
  description = "Content of private key used to connect to the target_host. If set to - no key is passed to openssh and ssh will use its own configuration"
  default     = "-"
}

variable "ignore_systemd_errors" {
  type        = bool
  description = "Ignore systemd errors happening during deploy"
  default     = false
}

variable "install_bootloader" {
  type        = bool
  description = "Install/re-install the bootloader"
  default     = false
}
