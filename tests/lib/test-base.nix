test:
{ pkgs
, nixos-anywhere
, disko
, kexec-installer
, system-to-install
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
  node.specialArgs.inputs = { inherit nixos-anywhere disko kexec-installer system-to-install; };
  imports = [ test ];
}).config.result
