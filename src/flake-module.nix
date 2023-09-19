{
  perSystem = { config, pkgs, ... }: {
    packages = rec {
      nixos-anywhere = pkgs.callPackage ./. { };
      nixos-anywhere-pxe = pkgs.callPackage ./nixos_anywhere_pxe { inherit nixos-anywhere; };
      default = config.packages.nixos-anywhere;
    };
    devShells.default = config.packages.nixos-anywhere.devShell;
  };
}
