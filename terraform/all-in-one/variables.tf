variable "kexec_tarball_url" {
  type = string
  description = "NixOS kexec installer tarball url"
  default = null
}

# To make this re-usuable we maybe should accept a store path here?
variable "nixos_partitioner_attr" {
  type        = string
  description = "Nixos partitioner and mount script i.e. your-flake#nixosConfigurations.your-evaluated-nixos.config.system.build.diskoNoDeps or just your-evaluated.config.system.build.diskNoDeps. `config.system.build.diskNoDeps` is provided by the disko nixos module"
}

# To make this re-usuable we maybe should accept a store path here?
variable "nixos_system_attr" {
  type        = string
  description = "The nixos system to deploy i.e. your-flake#nixosConfigurations.your-evaluated-nixos.config.system.build.toplevel or just your-evaluated-nixos.config.system.build.toplevel if you are not using flakes"
}

variable "file" {
  type        = string
  description = "Nix file containing the nixos_system_attr and nixos_partitioner_attr. Use this if you are not using flake"
  default     = null
}

variable "target_host" {
  type        = string
  description = "DNS host to deploy to"
}

variable "install_user" {
  type        = string
  description = "SSH user used to connect to the target_host, before installing NixOS. If null than the value of `target_host` is used"
  default     = null
}

variable "target_user" {
  type        = string
  description = "SSH user used to connect to the target_host after installing NixOS. If install_user is not set than this user is also used before installing."
  default     = "root"
}

variable "target_port" {
  type        = number
  description = "SSH port used to connect to the target_host, before installing NixOS"
  default     = 22
}

variable "instance_id" {
  type        = string
  description = "The instance id of the target_host, used to track when to reinstall the machine"
  default     = null
}

variable "install_ssh_key" {
  type        = string
  description = "Content of private key used to connect to the target_host during initial installation"
  default     = null
}

variable "deployment_ssh_key" {
  type        = string
  description = "Content of private key used to deploy to the target_host after initial installation. To ensure maximum security, it is advisable to connect to your host using ssh-agent instead of relying on this variable"
  default     = null
}

variable "debug_logging" {
  type        = bool
  description = "Enable debug logging"
  default     = false
}

variable "stop_after_disko" {
  type        = bool
  description = "Exit after disko formating"
  default     = false
}
