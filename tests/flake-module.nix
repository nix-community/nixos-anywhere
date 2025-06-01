{ withSystem, inputs, ... }:

{
  flake.checks.x86_64-linux = withSystem "x86_64-linux" ({ pkgs, system, inputs', config, ... }:
    let
      system-to-install = pkgs.nixos [
        ./modules/system-to-install.nix
        inputs.disko.nixosModules.disko
      ];
      testInputsUnstable = {
        inherit pkgs;
        inherit (inputs.disko.nixosModules) disko;
        nixos-anywhere = config.packages.nixos-anywhere;
        kexec-installer = "${inputs'.nixos-images.packages.kexec-installer-nixos-unstable-noninteractive}/nixos-kexec-installer-noninteractive-${system}.tar.gz";
        inherit system-to-install;
      };
      testInputsStable = testInputsUnstable // {
        kexec-installer = "${inputs'.nixos-images.packages.kexec-installer-nixos-stable-noninteractive}/nixos-kexec-installer-noninteractive-${system}.tar.gz";
      };
      linuxTestInputs = testInputsUnstable // {
        nix-vm-test = inputs.nix-vm-test;
      };
    in
    {
      from-nixos = import ./from-nixos.nix testInputsUnstable;
      from-nixos-stable = import ./from-nixos.nix testInputsStable;
      from-nixos-with-sudo = import ./from-nixos-with-sudo.nix testInputsUnstable;
      from-nixos-with-sudo-stable = import ./from-nixos-with-sudo.nix testInputsStable;
      from-nixos-with-generated-config = import ./from-nixos-generate-config.nix testInputsUnstable;
      from-nixos-build-on-remote = import ./from-nixos-build-on-remote.nix testInputsUnstable;
      from-nixos-separated-phases = import ./from-nixos-separated-phases.nix testInputsUnstable;
      ubuntu-kexec-test = import ./linux-kexec-test.nix (linuxTestInputs // {
        distribution = "ubuntu";
        version = "24_04";
      });
      fedora-kexec-test = import ./linux-kexec-test.nix (linuxTestInputs // {
        distribution = "fedora";
        version = "40";
      });
      debian-kexec-test = import ./linux-kexec-test.nix (linuxTestInputs // {
        distribution = "debian";
        version = "12";
      });
    });
}
