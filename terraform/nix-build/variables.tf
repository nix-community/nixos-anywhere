variable "attribute" {
  type        = string
  description = "the attribute to build, can also be a flake"
}

variable "file" {
  type        = string
  description = "the nix file to evaluate, if not run in flake mode"
  default     = null
}

variable "nix_options" {
  type        = map(string)
  description = "the options of nix"
  default     = {}
}

variable "special_args" {
  type        = any
  default     = {}
  description = "A map exposed as NixOS's `specialArgs` thru a file."
}

variable "debug_logging" {
  type        = bool
  default     = false
  description = "Enable debug logging"
}

variable "target_host" {
  type        = string
  default     = null
  description = "Target host to potentially use as remote builder"
}

variable "target_user" {
  type        = string
  default     = "root"
  description = "SSH user for target host"
}

variable "target_port" {
  type        = number
  default     = 22
  description = "SSH port for target host"
}

variable "use_target_as_builder" {
  type        = bool
  default     = false
  description = "Use target host as remote nix builder if it has nix available"
}
