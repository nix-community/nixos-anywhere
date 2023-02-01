{
  perSystem = { config, pkgs, ... }: {
    packages = {
      nixos-anywhere = pkgs.callPackage ./. { };
      default = config.packages.nixos-anywhere;
    };
    devShells.default = pkgs.mkShellNoCC {
      packages = config.packages.nixos-anywhere.runtimeInputs;
    };
  };
}
