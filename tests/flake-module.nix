{ withSystem, inputs, ... }:

{
  flake.checks.x86_64-linux = withSystem "x86_64-linux" ({ pkgs, system, inputs', config, ... }:
    let
      testInputs = {
        inherit pkgs system;
        inherit (inputs.disko.nixosModules) disko;
        nixos-remote = config.packages.nixos-remote;
        kexec-installer = builtins.fetchurl {
          url = "https://github.com/dep-sys/nix-dabei/releases/download/v0.5/nixos-kexec-installer-x86_64-linux.tar.gz";
          sha256 = "sha256:18b0mb714jzfrpvg19bw77h16s78ig8l24mqnrx4z73gzlfvrz7g";
          break it
        };
      };
    in
    {
      from-nixos = import ./from-nixos.nix testInputs;
      from-nixos-with-sudo = import ./from-nixos-with-sudo.nix testInputs;
    });
}
