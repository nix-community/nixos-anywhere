# Terraform Test Configuration for nixos-anywhere Hetzner Cloud deployment
# Run with: tofu test -var="hcloud_token=your-token-here"
# These tests require a valid Hetzner Cloud API token

variables {
  test_name_prefix = "tftest-nixos-anywhere"
}

run "test_hcloud_deployment_apply" {
  command = apply

  module {
    source = "./hcloud"
  }

  variables {
    nixos_system_attr      = "github:nix-community/nixos-anywhere-examples#nixosConfigurations.hetzner-cloud.config.system.build.toplevel"
    nixos_partitioner_attr = "github:nix-community/nixos-anywhere-examples#nixosConfigurations.hetzner-cloud.config.system.build.diskoNoDeps"
    debug_logging          = true
  }

  assert {
    condition     = output.nixos_anywhere_result != null
    error_message = "nixos-anywhere deployment should produce a result"
  }
}
