{ config, lib, pkgs, inputs, ... }:
let
  disko = inputs.disko; #or "${builtins.fetchTarball "https://github.com/nix-community/disko/archive/master.tar.gz"}/module.nix";
  kexec-installer = builtins.fetchurl {
    url = "https://github.com/dep-sys/nix-dabei/releases/download/v0.9.2/nixos-kexec-installer-x86_64-linux.tar.gz";
    sha256 = "sha256:1zb33a15qfxbs38swnpyla7gc8mn4p2hc832ywz9d8ip57qdq7hd";
  };
  system-to-install = pkgs.nixos [
    ./system-to-install.nix
    disko
  ];
in
{
  system.activationScripts.rsa-key = ''
    ${pkgs.coreutils}/bin/install -D -m600 ${./ssh-keys/ssh} /root/.ssh/id_rsa
  '';

  environment.systemPackages = [ inputs.nixos-anywhere ];

  environment.etc = {
    "nixos-anywhere/disko".source = system-to-install.config.system.build.disko;
    "nixos-anywhere/system-to-install".source = system-to-install.config.system.build.toplevel;
    "nixos-anywhere/kexec-installer".source = kexec-installer;
  };
}
