{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
    terraform-providers-bin.url = "github:numtide/nixpkgs-terraform-providers-bin";
    terraform-providers-bin.inputs.nixpkgs.follows = "nixpkgs";
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, utils, terraform-providers-bin, devshell }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ devshell.overlays.default ];
        };
        tfProviders = (terraform-providers-bin.legacyPackages.${system}).providers;
        tf = pkgs.terraform.withPlugins (
          p: [
            tfProviders.dmacvicar.libvirt
            tfProviders.hashicorp.external
            tfProviders.hashicorp.null
            tfProviders.hashicorp.local
            tfProviders.hashicorp.terraform
          ]
        );
      in
      {
        devShell = pkgs.devshell.mkShell {
          packages = with pkgs; [
            tf
            go
            cdrtools
            gcc
          ];
          commands = [
            {
              name = "terratest";
              help = "Run terraform tests";
              command = "${pkgs.go}/bin/go test -v ./.";
            }
          ];
        };
      });
}

