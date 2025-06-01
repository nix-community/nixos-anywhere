# NixOS Anywhere Terraform Tests

This directory contains tests for the `nixos-anywhere` Terraform modules using
OpenTofu's built-in testing framework.

## Test Structure

```
terraform/tests/
├── main.tf                           # Core configuration for validation tests
├── nixos-anywhere.tftest.hcl         # Basic validation tests (no external deps)
├── nix-build-special-args.tftest.hcl # Nix build module tests with special_args
├── hcloud-deployment.tftest.hcl      # Hetzner Cloud integration tests
├── digitalocean-deployment.tftest.hcl # DigitalOcean integration tests
├── hcloud/                           # Hetzner Cloud deployment configuration
│   ├── main.tf
├── digitalocean/                     # DigitalOcean deployment configuration
    ├── main.tf
```

### For Cloud Provider Tests (Optional)

- Hetzner Cloud account with API token
- DigitalOcean account with API token

## Running Tests

### Basic Validation Tests (No External Dependencies)

```bash
# Enter development environment
nix develop .#terraform

# Initialize and run validation tests
cd terraform/tests
tofu init
tofu test

# Run Specific Test File
tofu test -filter=nixos-anywhere.tftest.hcl
```

**Current Status:** Tests available for nixos-anywhere module and nix-build
module

### Cloud Provider Integration Tests

#### Hetzner Cloud

```bash
# Set your Hetzner Cloud token
export TF_VAR_hcloud_token="your-64-character-hcloud-token"

# Run Hetzner Cloud tests
tofu test -filter hcloud-deployment.tftest.hcl
```

#### DigitalOcean

```bash
# Set your DigitalOcean token
export TF_VAR_digitalocean_token="your-digitalocean-api-token"

# Run DigitalOcean tests
tofu test -filter digitalocean-deployment.tftest.hcl
```

**Note:** These tests will fail if no valid token is provided.

## Test Categories

### 1. Validation Tests (`nixos-anywhere.tftest.hcl`)

- **Purpose:** Validate configuration structure and variables
- **Dependencies:** None (nixos-anywhere module only)
- **Duration:** 30-60 seconds
- **Cost:** Free

### 2. Nix Build Special Args Tests (`nix-build-special-args.tftest.hcl`)

- **Purpose:** Test nix-build module with special_args functionality
- **Dependencies:** None (nix-build module only)
- **Duration:** 30-60 seconds
- **Cost:** Free

### 3. Hetzner Cloud Tests (`hcloud-deployment.tftest.hcl`)

- **Purpose:** Test complete deployment workflow
- **Dependencies:** Valid Hetzner Cloud token
- **Duration:** 5 minutes (apply tests)
- **Cost:** ~€ 0.006 per hour

### 4. DigitalOcean Tests (`digitalocean-deployment.tftest.hcl`)

- **Purpose:** Test complete deployment workflow
- **Dependencies:** Valid DigitalOcean API token
- **Duration:** 5 minutes (apply tests)
- **Cost:** ~$0,02679 per hour

## Usage Examples

### Environment Variables

```bash
export TF_VAR_hcloud_token="your-hcloud-token"
export TF_VAR_digitalocean_token="your-digitalocean-token"
export TF_VAR_test_name_prefix="my-test"
```

### Variable File (Optional)

Create `terraform.tfvars`:

```hcl
hcloud_token = "your-hcloud-token-here"
digitalocean_token = "your-digitalocean-token-here"
test_name_prefix = "tftest-nixos-anywhere"
```

## Cleanup

OpenTofu test automatically cleans up resources. Manual cleanup if needed:

### Hetzner Cloud

```bash
# List test resources
hcloud server list | grep tftest-nixos-anywhere
hcloud ssh-key list | grep tftest-nixos-anywhere

# Force cleanup
hcloud server delete <server-id>
hcloud ssh-key delete <key-id>
```

### DigitalOcean

```bash
# List test resources
doctl compute droplet list | grep tftest-nixos-anywhere
doctl compute ssh-key list | grep tftest-nixos-anywhere

# Force cleanup
doctl compute droplet delete <droplet-id>
doctl compute ssh-key delete <key-id>
```

## Development

### Test Best Practices

- Use `command = plan` for validation tests
- Use `command = apply` sparingly for integration tests
- Include proper assertions with clear error messages
- Make tests conditional based on available credentials
