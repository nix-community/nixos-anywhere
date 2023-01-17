{
  perSystem = { config, pkgs, ... }: {
    packages = {
      nixos-remote = pkgs.callPackage ./. { };
      default = config.packages.nixos-remote;
    };
    devShells.default = pkgs.mkShellNoCC {
      packages = config.packages.nixos-remote.runtimeInputs;
    };
  };
}
