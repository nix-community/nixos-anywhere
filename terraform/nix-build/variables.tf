variable "attribute" {
  type = string
  description = "the attribute to build, can also be a flake"
}

variable "file" {
  type = string
  description = "the nix file to evaluate, if not run in flake mode"
  default = null
}

variable "nix_options" {
  type = map(string)
  description = "the options of nix"
  default = {}
}

variable "extra_build_env_vars" {
  type = map(string)
  description = "Extra environment variables to be passed to the build. If set, evaluation will use `--impure`."
  default = {}
}
