# Terraform Test Configuration for nixos-anywhere DigitalOcean deployment
# Run with: tofu test -var="digitalocean_token=your-token-here"
# These tests require a valid DigitalOcean API token

variables {
  test_name_prefix = "tftest-nixos-anywhere"
}

run "test_digitalocean_deployment_apply" {
  command = apply

  module {
    source = "./digitalocean"
  }

  variables {
    nixos_system_attr      = "github:nix-community/nixos-anywhere-examples#nixosConfigurations.digitalocean.config.system.build.toplevel"
    nixos_partitioner_attr = "github:nix-community/nixos-anywhere-examples#nixosConfigurations.digitalocean.config.system.build.diskoNoDeps"
    debug_logging          = true
  }

  assert {
    condition     = output.nixos_anywhere_result != null
    error_message = "nixos-anywhere deployment should produce a result"
  }
}
