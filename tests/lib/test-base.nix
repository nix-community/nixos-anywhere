test:
{ pkgs ? import <nixpkgs> { }, ... } @ args:
let
  inherit (pkgs) lib;
  nixos-lib = import (pkgs.path + "/nixos/lib") { };
in
(nixos-lib.runTest {
  hostPkgs = pkgs;
  # speed-up evaluation
  defaults.documentation.enable = lib.mkDefault false;
  # to accept external dependencies such as disko
  node.specialArgs.inputs = args;
  imports = [ test ];
}).config.result
