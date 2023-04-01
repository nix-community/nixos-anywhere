{ pkgs ? import <nixpkgs> {} }:
let
  system-to-install = pkgs.nixos [
    ../../../modules/system-to-install.nix
    "${builtins.fetchTarball "https://github.com/nix-community/disko/archive/master.tar.gz"}/module.nix"
    ({
      services.openssh.enable = true;
      users.users.root.openssh.authorizedKeys.keyFiles = [ ../../../modules/ssh-keys/ssh.pub ];
    })
  ];
in
rec {
  system = system-to-install.config.system.build.toplevel;
  disko = system-to-install.config.system.build.disko;
}
