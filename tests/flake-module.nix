{ withSystem, inputs, ... }:

{
  flake.checks.x86_64-linux = withSystem "x86_64-linux" ({ pkgs, system, inputs', config, ... }:
    let
      testInputsUnstable = {
        inherit pkgs;
        inherit (inputs.disko.nixosModules) disko;
        nixos-anywhere = config.packages.nixos-anywhere;
        kexec-installer = "${inputs'.nixos-images.packages.kexec-installer-nixos-unstable-noninteractive}/nixos-kexec-installer-noninteractive-${system}.tar.gz";
      };
      testInputsStable = testInputsUnstable // {
        kexec-installer = "${inputs'.nixos-images.packages.kexec-installer-nixos-2311-noninteractive}/nixos-kexec-installer-noninteractive-${system}.tar.gz";
      };
    in
    {
      from-nixos = import ./from-nixos.nix testInputsUnstable;
      from-nixos-stable = import ./from-nixos.nix testInputsStable;
      from-nixos-with-sudo = import ./from-nixos-with-sudo.nix testInputsUnstable;
      from-nixos-with-sudo-stable = import ./from-nixos-with-sudo.nix testInputsStable;
    });
}
