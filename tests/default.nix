{ pkgs, inputs, nixos-anywhere }:
let
  system = pkgs.stdenv.hostPlatform.system;
  system-to-install = pkgs.nixos [
    ./modules/system-to-install.nix
    inputs.disko.nixosModules.disko
  ];
  testInputsUnstable = {
    inherit pkgs nixos-anywhere system-to-install;
    inherit (inputs.disko.nixosModules) disko;
    kexec-installer = "${inputs.nixos-images.packages.${system}.kexec-installer-nixos-unstable-noninteractive}/nixos-kexec-installer-noninteractive-${system}.tar.gz";
  };
  testInputsStable = testInputsUnstable // {
    kexec-installer = "${inputs.nixos-images.packages.${system}.kexec-installer-nixos-stable-noninteractive}/nixos-kexec-installer-noninteractive-${system}.tar.gz";
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
    version = "43";
  });
  debian-kexec-test = import ./linux-kexec-test.nix (linuxTestInputs // {
    distribution = "debian";
    version = "12";
  });
}
