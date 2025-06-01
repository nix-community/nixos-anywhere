# Terraform Test Configuration for nix-build module with special_args
# Tests the fix for nested flakes in git repositories
# Run with: tofu test

variables {
  test_name_prefix = "tftest-nix-build-special-args"
}

# Test: nix-build module with special_args using terraform-test configuration
run "validate_nix_build_special_args" {
  command = plan

  module {
    source = "../nix-build"
  }

  variables {
    attribute = ".#nixosConfigurations.terraform-test.config.system.build.toplevel"
    special_args = {
      terraform = {
        hostname      = "special-args-test-host"
        ip_address    = "192.168.1.100"
        environment   = "testing"
        deployment_id = "test-001"
      }
    }
  }

  assert {
    condition     = var.special_args.terraform.hostname == "special-args-test-host"
    error_message = "special_args should preserve hostname value"
  }

  assert {
    condition     = var.special_args.terraform.environment == "testing"
    error_message = "special_args should preserve environment value"
  }

  assert {
    condition     = var.attribute == ".#nixosConfigurations.terraform-test.config.system.build.toplevel"
    error_message = "should use terraform-test configuration"
  }
}