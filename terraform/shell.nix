{ mkShell
, terraform-docs
, opentofu
}:
mkShell {
  buildInputs = [
    terraform-docs
    (opentofu.withPlugins (p: [
      p.digitalocean_digitalocean
      p.hashicorp_external
      p.hetznercloud_hcloud
      p.hashicorp_local
      p.hashicorp_null
      p.hashicorp_tls
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
