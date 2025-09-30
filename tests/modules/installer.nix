{ pkgs, inputs, lib, ... }:
{
  system.activationScripts.rsa-key = ''
    ${pkgs.coreutils}/bin/install -D -m600 ${./ssh-keys/ssh} /root/.ssh/install_key
  '';

  environment.systemPackages = [ inputs.nixos-anywhere ];
  services.getty.autologinUser = lib.mkForce "root";
  console.earlySetup = true;
  environment.etc = {
    "nixos-anywhere/disko".source = inputs.system-to-install.config.system.build.diskoScriptNoDeps;
    "nixos-anywhere/system-to-install".source = inputs.system-to-install.config.system.build.toplevel;
    "nixos-anywhere/kexec-installer.tar.gz".source = inputs.kexec-installer;
  };
}
