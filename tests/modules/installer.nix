{ pkgs, inputs, ... }:
let
  disko = inputs.disko;
  kexec-installer = inputs.kexec-installer;
  system-to-install = pkgs.nixos [
    ./system-to-install.nix
    disko
  ];
in
{
  system.activationScripts.rsa-key = ''
    ${pkgs.coreutils}/bin/install -D -m600 ${./ssh-keys/ssh} /root/.ssh/install_key
  '';

  environment.systemPackages = [ inputs.nixos-anywhere ];

  environment.etc = {
    "nixos-anywhere/disko".source = system-to-install.config.system.build.diskoScript;
    "nixos-anywhere/system-to-install".source = system-to-install.config.system.build.toplevel;
    "nixos-anywhere/kexec-installer".source = kexec-installer;
  };
}
