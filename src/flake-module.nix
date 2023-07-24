{
  perSystem = { config, pkgs, ... }: {
    packages = {
      nixos-anywhere = pkgs.callPackage ./. { };
      nixos-anywhere-pxe = pkgs.callPackage ./nixos_anywhere_pxe { };
      default = config.packages.nixos-anywhere;
    };
    devShells.default = config.packages.nixos-anywhere.devShell;
  };
}
