variable "attribute" {
  type = string
  description = "the attribute to build, can also be a flake"
}

variable "file" {
  type = string
  description = "the nix file to evaluate, if not run in flake mode"
  default = null
}

variable "nix_argstrs" {
  type = map(string)
  description = "the argstrs of nix"
  default = {}
}

variable "nix_options" {
  type = map(string)
  description = "the options of nix"
  default = {}
}

variable "special_args" {
  type = any
  default = {}
  description = "A map exposed as NixOS's `specialArgs` thru a file."
}
