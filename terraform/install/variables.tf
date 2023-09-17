variable "kexec_tarball_url" {
  type        = string
  description = "NixOS kexec installer tarball url"
  default     = null
}

# To make this re-usable we maybe should accept a store path here?
variable "nixos_partitioner" {
  type        = string
  description = "nixos partitioner and mount script"
}

# To make this re-usable we maybe should accept a store path here?
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
  description = "SSH user used to connect to the target_host"
  default     = "root"
}

variable "target_port" {
  type        = number
  description = "SSH port used to connect to the target_host"
  default     = 22
}

variable "ssh_private_key" {
  type        = string
  description = "Content of private key used to connect to the target_host"
  default     = ""
}

variable "instance_id" {
  type        = string
  description = "The instance id of the target_host, used to track when to reinstall the machine"
  default     = null
}

variable "debug_logging" {
  type        = bool
  description = "Enable debug logging"
  default     = false
}

variable "stop_after_disko" {
  type        = bool
  description = "Exit after disko formatting"
  default     = false
}

variable "extra_files_script" {
  type        = string
  description = "A script file that prepares extra files to be copied to the target host during installation. The script expected to write all its files to the current directory. This directory is rsynced to the target host during installation to the / directory."
  default     = null
}

variable "disk_encryption_key_scripts" {
  type        = list(object({
    path = string
    script = string
  }))
  description = "Each of these script files will be executed locally and the output of each of them will be made present at the given path to disko during installation. The keys will be not copied to the final system"
  default     = []
}

variable "extra_environment" {
  type        = map(string)
  description = "Extra environment variables to be set during installation. This can be usefull to set extra variables for the extra_files_script or disk_encryption_key_scripts"
  default     = {}
}

variable "no_reboot" {
  type        = bool
  description = "Do not reboot the machine after installation"
  default     = false
}
