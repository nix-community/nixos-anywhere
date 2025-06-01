{
  perSystem = { pkgs, ... }: {
    devShells.terraform = pkgs.mkShell {
      buildInputs = with pkgs; [
        terraform-docs
        (opentofu.withPlugins (p: [
          p.tls
          p.hcloud
          p.local
          p.external
          p.null
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
