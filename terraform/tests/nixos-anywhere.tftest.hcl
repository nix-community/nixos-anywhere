# Terraform Test Configuration for nixos-anywhere all-in-one module
# Run with: tofu test

variables {
  test_name_prefix = "tftest-nixos-anywhere"
}

# Test: Basic variable validation
run "validate_basic_config" {
  command = plan

  variables {
    nixos_system_attr      = ".#nixosConfigurations.terraform-test.config.system.build.toplevel"
    nixos_partitioner_attr = ".#nixosConfigurations.terraform-test.config.system.build.diskoNoDeps"
    target_host            = "1.2.3.4"
    debug_logging          = true
  }

  assert {
    condition     = var.nixos_system_attr != ""
    error_message = "NixOS system attribute must be specified"
  }

  assert {
    condition     = var.nixos_partitioner_attr != ""
    error_message = "NixOS partitioner attribute must be specified"
  }

  assert {
    condition     = var.target_host != ""
    error_message = "Target host must be specified"
  }
}

# Test: Variable validation with custom values
run "validate_variables" {
  command = plan

  variables {
    nixos_system_attr      = ".#nixosConfigurations.terraform-test.config.system.build.toplevel"
    nixos_partitioner_attr = ".#nixosConfigurations.terraform-test.config.system.build.diskoNoDeps"
    target_host            = "test.example.com"
    target_port            = 2222
    target_user            = "deploy"
    debug_logging          = true
    phases                 = ["kexec", "disko", "install"]
    build_on_remote        = true
  }

  assert {
    condition     = var.target_port == 2222
    error_message = "Target port should be configurable"
  }

  assert {
    condition     = var.target_user == "deploy"
    error_message = "Target user should be configurable"
  }

  assert {
    condition     = contains(var.phases, "kexec")
    error_message = "Phases should include kexec"
  }

  assert {
    condition     = var.build_on_remote == true
    error_message = "Build on remote should be configurable"
  }

  assert {
    condition     = var.debug_logging == true
    error_message = "Debug logging should be configurable"
  }
}

# Test: Default values
run "validate_defaults" {
  command = plan

  variables {
    nixos_system_attr      = ".#nixosConfigurations.terraform-test.config.system.build.toplevel"
    nixos_partitioner_attr = ".#nixosConfigurations.terraform-test.config.system.build.diskoNoDeps"
    target_host            = "192.168.1.100"
  }

  assert {
    condition     = var.target_port == 22
    error_message = "Default target port should be 22"
  }

  assert {
    condition     = var.target_user == "root"
    error_message = "Default target user should be root"
  }

  assert {
    condition     = var.debug_logging == false
    error_message = "Default debug logging should be false"
  }

  assert {
    condition     = var.build_on_remote == false
    error_message = "Default build_on_remote should be false"
  }

  assert {
    condition     = contains(var.phases, "kexec")
    error_message = "Default phases should include kexec"
  }

  assert {
    condition     = contains(var.phases, "disko")
    error_message = "Default phases should include disko"
  }

  assert {
    condition     = contains(var.phases, "install")
    error_message = "Default phases should include install"
  }
}