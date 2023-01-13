variable "attribute" {
  type = string
  description = "the attribute to build, can also be a flake"
}

variable "file" {
  type = string
  description = "the nix file to evaluate, if not run in flake mode"
  default = null
}
