{
  description = "A universal nixos installer, just needs ssh access to the target system";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  inputs.disko.url = "github:nix-community/disko/master";
  inputs.disko.inputs.nixpkgs.follows = "nixpkgs";
  # used for testing
  inputs.nixos-images.url = "github:nix-community/nixos-images";

  outputs = { self, disko, nixpkgs, nixos-images, ... }:
    let
      supportedSystems = [
        "x86_64-linux"
        "i686-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      packages = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system}; in
        {
          default = self.packages.${system}.nixos-remote;
          docs = pkgs.callPackage ./docs { };
          nixos-remote = pkgs.callPackage ./nixos-remote.nix { };
        });
      checks.x86_64-linux =
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
        in
        {
          from-nixos = import ./tests/from-nixos.nix {
            inherit pkgs;
            disko = disko.nixosModules.disko;
            kexec-installer = "${nixos-images.packages.${pkgs.system}.kexec-installer-nixos-unstable}/nixos-kexec-installer-${pkgs.stdenv.hostPlatform.system}.tar.gz";
            makeTest = import (pkgs.path + "/nixos/tests/make-test-python.nix");
            eval-config = import (pkgs.path + "/nixos/lib/eval-config.nix");
          };
        };
    };
}
