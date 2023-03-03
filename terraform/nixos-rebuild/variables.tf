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
