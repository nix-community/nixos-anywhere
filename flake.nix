{
  description = "A universal nixos installer, just needs ssh access to the target system";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable-small";

    # used for testing
    disko = { url = "github:nix-community/disko/master"; inputs.nixpkgs.follows = "nixpkgs"; };
    nixos-stable.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixos-images.url = "github:nix-community/nixos-images";
    nixos-images.inputs.nixos-unstable.follows = "nixpkgs";
    nixos-images.inputs.nixos-stable.follows = "nixos-stable";
    # https://github.com/numtide/nix-vm-test/pull/105 rebased onto main for the new test-driver CLI
    nix-vm-test = { url = "github:Mic92/nix-vm-test/rebased-pr-105"; inputs.nixpkgs.follows = "nixpkgs"; };

    # used for development
    treefmt-nix = { url = "github:numtide/treefmt-nix"; inputs.nixpkgs.follows = "nixpkgs"; };
  };

  outputs = inputs@{ self, nixpkgs, ... }:
    let
      lib = nixpkgs.lib;
      systems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
      eachSystem = f: lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

      # allow to disable treefmt in downstream flakes
      hasTreefmt = inputs.treefmt-nix ? lib;
      treefmtEval = eachSystem (pkgs: inputs.treefmt-nix.lib.evalModule pkgs ./treefmt.nix);
    in
    {
      packages = eachSystem (pkgs: {
        nixos-anywhere = pkgs.callPackage ./src { };
        default = self.packages.${pkgs.stdenv.hostPlatform.system}.nixos-anywhere;
        docs = pkgs.callPackage ./docs { };
      });

      devShells = eachSystem (pkgs: {
        default = self.packages.${pkgs.stdenv.hostPlatform.system}.nixos-anywhere.devShell;
        terraform = pkgs.callPackage ./terraform/shell.nix { };
      });

      formatter = lib.optionalAttrs hasTreefmt
        (eachSystem (pkgs: treefmtEval.${pkgs.stdenv.hostPlatform.system}.config.build.wrapper));

      nixosConfigurations.terraform-test = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./tests/modules/system-to-install.nix
          inputs.disko.nixosModules.disko
          (args: {
            # Example usage of special args from terraform
            networking.hostName = args.terraform.hostname or "nixos-anywhere";

            # Create testable files in /etc based on terraform special_args
            environment.etc = {
              "terraform-config.json" = {
                text = builtins.toJSON args.terraform or { };
                mode = "0644";
              };
            };
          })
        ];
      };

      checks = eachSystem (pkgs:
        let
          system = pkgs.stdenv.hostPlatform.system;
          packages = lib.mapAttrs' (n: lib.nameValuePair "package-${n}") self.packages.${system};
          devShells = lib.mapAttrs' (n: lib.nameValuePair "devShell-${n}") self.devShells.${system};
          vmTests = lib.optionalAttrs (system == "x86_64-linux")
            (import ./tests {
              inherit pkgs inputs;
              nixos-anywhere = self.packages.${system}.nixos-anywhere;
            });
        in
        packages // devShells // vmTests);
    };
}
