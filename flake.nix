{
  description = "A universal nixos installer, just needs ssh access to the target system";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable-small";
    flake-parts = { url = "github:hercules-ci/flake-parts"; inputs.nixpkgs-lib.follows = "nixpkgs"; };

    # used for testing
    disko = { url = "github:nix-community/disko/master"; inputs.nixpkgs.follows = "nixpkgs"; };
    nixos-stable.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixos-images.url = "github:nix-community/nixos-images";
    nixos-images.inputs.nixos-unstable.follows = "nixpkgs";
    nixos-images.inputs.nixos-stable.follows = "nixos-stable";
    # https://github.com/numtide/nix-vm-test/pull/105
    nix-vm-test = { url = "github:Mic92/nix-vm-test"; inputs.nixpkgs.follows = "nixpkgs"; };

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
        ./terraform/flake-module.nix
        # allow to disable treefmt in downstream flakes
      ] ++ inputs.nixpkgs.lib.optional (inputs.treefmt-nix ? flakeModule) ./treefmt/flake-module.nix;

      perSystem = { self', lib, ... }: {
        checks =
          let
            packages = lib.mapAttrs' (n: lib.nameValuePair "package-${n}") self'.packages;
            devShells = lib.mapAttrs' (n: lib.nameValuePair "devShell-${n}") self'.devShells;
          in
          packages // devShells;
      };
    };
}
