{
  description = "A universal nixos installer, just needs ssh access to the target system";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable-small";
    flake-parts = { url = "github:hercules-ci/flake-parts"; inputs.nixpkgs-lib.follows = "nixpkgs"; };
    disko = { url = "github:nix-community/disko/master"; inputs.nixpkgs.follows = "nixpkgs"; };
    # used for development
    treefmt-nix.url = "github:numtide/treefmt-nix";
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

      perSystem = { config, ... }: {
        treefmt = {
          projectRootFile = "flake.nix";
          programs.nixpkgs-fmt.enable = true;
          programs.shellcheck.enable = true;
          programs.shfmt.enable = true;
          settings.formatter.shellcheck.options = [ "-s" "bash" ];
        };
        formatter = config.treefmt.build.wrapper;
      };
    };
}
