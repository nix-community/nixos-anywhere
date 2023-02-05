{ withSystem, inputs, ... }:

{
  flake.checks.x86_64-linux = withSystem "x86_64-linux" ({ pkgs, system, inputs', config, ... }:
    let
      testInputs = {
        inherit pkgs system;
        inherit (inputs.disko.nixosModules) disko;
        nixos-anywhere = config.packages.nixos-anywhere;
        kexec-installer = builtins.fetchurl {
          url = "https://github.com/dep-sys/nix-dabei/releases/download/v0.9.2/nixos-kexec-installer-x86_64-linux.tar.gz";
          sha256 = "sha256:0zd38hyklci21zzl85ahjzgh4jh1i7ibdyralm1gmm6dsinnayn3";
        };
      };
    in
    {
      from-nixos = import ./from-nixos.nix testInputs;
      from-nixos-with-sudo = import ./from-nixos-with-sudo.nix testInputs;
    });
}
