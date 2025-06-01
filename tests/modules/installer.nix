{ pkgs, inputs, ... }:
{
  system.activationScripts.rsa-key = ''
    ${pkgs.coreutils}/bin/install -D -m600 ${./ssh-keys/ssh} /root/.ssh/install_key
  '';

  environment.systemPackages = [ inputs.nixos-anywhere ];

  environment.etc = {
    "nixos-anywhere/disko".source = inputs.system-to-install.config.system.build.diskoScriptNoDeps;
    "nixos-anywhere/system-to-install".source = inputs.system-to-install.config.system.build.toplevel;
    "nixos-anywhere/kexec-installer".source = inputs.kexec-installer;
  };
}
