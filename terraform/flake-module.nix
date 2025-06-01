{ inputs, ... }:
{
  flake.nixosConfigurations.terraform-test = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ../tests/modules/system-to-install.nix
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

  perSystem = { pkgs, ... }: {
    devShells.terraform = pkgs.mkShell {
      buildInputs = with pkgs; [
        terraform-docs
        (opentofu.withPlugins (p: [
          p.digitalocean
          p.external
          p.hcloud
          p.local
          p.null
          p.tls
        ]))
      ];

      shellHook = ''
        echo "🚀 Terraform development environment"
        echo "Available tools:"
        echo "  - terraform-docs"
        echo "  - opentofu"
        echo ""
        echo "To run tests: cd terraform/tests && tofu test"
        echo "To update docs: cd terraform && ./update-docs.sh"
      '';
    };
  };
}
