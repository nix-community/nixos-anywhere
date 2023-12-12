{ withSystem, inputs, ... }:

{
  flake.checks.x86_64-linux = withSystem "x86_64-linux" ({ pkgs, system, inputs', config, ... }:
    let
      testInputs = {
        inherit pkgs;
        inherit (inputs.disko.nixosModules) disko;
        nixos-anywhere = config.packages.nixos-anywhere;
        kexec-installer = "${inputs'.nixos-images.packages.kexec-installer-nixos-unstable-noninteractive}/nixos-kexec-installer-noninteractive-${system}.tar.gz";
      };
      testInputs2311 = testInputs // {
        kexec-installer = "${inputs'.nixos-images.packages.kexec-installer-nixos-2311-noninteractive}/nixos-kexec-installer-noninteractive-${system}.tar.gz";
      };
    in
    {
      from-nixos = import ./from-nixos.nix testInputs;
      from-nixos-2311 = import ./from-nixos.nix testInputs2311;
      from-nixos-with-sudo = import ./from-nixos-with-sudo.nix testInputs;
      from-nixos-with-sudo-2311 = import ./from-nixos-with-sudo.nix testInputs2311;
    });
}
