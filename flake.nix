{
  description = "A universal nixos installer, just needs ssh access to the target system";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable-small";
    flake-parts = { url = "github:hercules-ci/flake-parts"; inputs.nixpkgs-lib.follows = "nixpkgs"; };
    disko = { url = "github:nix-community/disko/master"; inputs.nixpkgs.follows = "nixpkgs"; };
    # used for testing
    nixos-2305.url = "github:NixOS/nixpkgs/release-23.05";
    nixos-images.url = "github:nix-community/nixos-images";
    nixos-images.inputs.nixos-unstable.follows = "nixpkgs";
    nixos-images.inputs.nixos-2305.follows = "nixos-2305";
    # used for development
    treefmt-nix = { url = "github:numtide/treefmt-nix"; inputs.nixpkgs.follows = "nixpkgs"; };
  };


  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
      imports = [
        ./src/flake-module.nix
        ./tests/flake-module.nix
        ./docs/flake-module.nix
        inputs.treefmt-nix.flakeModule
      ];

      perSystem = { self', config, lib, ... }: {
        treefmt = {
          projectRootFile = "flake.nix";
          programs.mdsh.enable = true;
          programs.nixpkgs-fmt.enable = true;
          programs.shellcheck.enable = true;
          programs.shfmt.enable = true;
          programs.prettier.enable = true;
          settings.formatter.prettier.options = [ "--prose-wrap" "always" ];
          settings.formatter.shellcheck.options = [ "-s" "bash" ];
        };
        formatter = config.treefmt.build.wrapper;

        checks =
          let
            packages = lib.mapAttrs' (n: lib.nameValuePair "package-${n}") self'.packages;
            devShells = lib.mapAttrs' (n: lib.nameValuePair "devShell-${n}") self'.devShells;
          in
          packages // devShells;
      };
    };
}
