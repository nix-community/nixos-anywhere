test:
{ pkgs ? import <nixpkgs> { }
, nixos-anywhere ? pkgs.callPackage ../../src { }
, disko ? "${builtins.fetchTarball "https://github.com/nix-community/disko/archive/master.tar.gz"}/module.nix"
, kexec-installer ? builtins.fetchurl "https://github.com/nix-community/nixos-images/releases/download/nixos-unstable/nixos-kexec-installer-noninteractive-${pkgs.stdenv.hostPlatform.system}.tar.gz"
, ...
}:
let
  inherit (pkgs) lib;
  nixos-lib = import (pkgs.path + "/nixos/lib") { };
in
(nixos-lib.runTest {
  hostPkgs = pkgs;
  # speed-up evaluation
  defaults.documentation.enable = lib.mkDefault false;
  # to accept external dependencies such as disko
  node.specialArgs.inputs = { inherit nixos-anywhere disko kexec-installer; };
  imports = [ test ];
}).config.result
