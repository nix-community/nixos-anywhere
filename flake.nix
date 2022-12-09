{
  description = "Install nixos everywhere via ssh";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs, ... }: let
    supportedSystems = [
      "x86_64-linux"
      "i686-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
  in {
    packages = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      nixos-remote = pkgs.callPackage ./package.nix {};
      default = self.packages.${system}.nixos-remote;
    });
  };
}
