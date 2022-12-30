{ config, lib, pkgs, inputs, ... }:
let
  disko = inputs.disko; #or "${builtins.fetchTarball "https://github.com/nix-community/disko/archive/master.tar.gz"}/module.nix";
  kexec-installer = inputs.kexec-installer; # or builtins.fetchurl "https://github.com/nix-community/nixos-images/releases/download/nixos-unstable/nixos-kexec-installer-${pkgs.stdenv.hostPlatform.system}.tar.gz";
  system-to-install = pkgs.nixos [
    ./system-to-install.nix
    disko
  ];
in
{
  programs.ssh.startAgent = true;

  environment.etc = {
    sshKey = { source = ./ssh-keys/ssh;  mode = "0600"; };
    "nixos-remote/disko".source = system-to-install.config.system.build.disko;
    "nixos-remote/system-to-install".source = system-to-install.config.system.build.toplevel;
    "nixos-remote/kexec-installer".source = kexec-installer;
  };
}
