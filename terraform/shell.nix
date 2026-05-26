{ mkShell
, terraform-docs
, opentofu
}:
mkShell {
  buildInputs = [
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
}
