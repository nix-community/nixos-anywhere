{
  virtualisation.memorySize = 4096;
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keyFiles = [ ./ssh-keys/ssh.pub ];
}
