{
  virtualisation.memorySize = 4096;
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keyFiles = [ ./ssh-keys/ssh.pub ];
  users.users.nixos = {
    isNormalUser = true;
    openssh.authorizedKeys.keyFiles = [ ./ssh-keys/ssh.pub ];
    extraGroups = [ "wheel" ];
  };
  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = false;
}
