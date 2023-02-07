{
  perSystem = { config, pkgs, ... }: {
    packages = {
      nixos-anywhere = pkgs.callPackage ./. { };
      default = config.packages.nixos-anywhere;
    };
    devShells.default = config.packages.nixos-anywhere.devShell;
  };
}
