# Secrets and full disk encryption

The `nixos-anywhere` utility offers the capability to install secrets onto a
target machine. This feature is particularly beneficial when you want to
bootstrap secrets management tools such as
[sops-nix](https://github.com/Mic92/sops-nix) or
[agenix](https://github.com/ryantm/agenix), which rely on machine-specific
secrets to decrypt other uploaded secrets.

## Example: Decrypting an OpenSSH Host Key with pass

In this example, we demonstrate how to use a script to decrypt an OpenSSH host
key from the `pass` password manager and subsequently pass it to
`nixos-anywhere` during the installation process:

```bash
#!/usr/bin/env bash

# Create a temporary directory
temp=$(mktemp -d)

# Function to cleanup temporary directory on exit
cleanup() {
  rm -rf "$temp"
}
trap cleanup EXIT

# Create the directory where sshd expects to find the host keys
install -d -m755 "$temp/etc/ssh"

# Decrypt your private key from the password store and copy it to the temporary directory
pass ssh_host_ed25519_key > "$temp/etc/ssh/ssh_host_ed25519_key"

# Set the correct permissions so sshd will accept the key
chmod 600 "$temp/etc/ssh/ssh_host_ed25519_key"

# Install NixOS to the host system with our secrets
nixos-anywhere --extra-files "$temp" --flake '.#your-host' --target-host root@yourip
```

## Example: Uploading Disk Encryption Secrets

In a similar vein, `nixos-anywhere` can upload disk encryption secrets, which
are necessary during formatting with disko. Here's an example that demonstrates
how to provide your disk encryption password as a file or via the `pass` utility
to `nixos-anywhere`:

```bash
# Write your disk encryption password to a file
echo "my-super-safe-password" > /tmp/disk-1.key

# Call nixos-anywhere with disk encryption keys
nixos-anywhere \
  --disk-encryption-keys /tmp/disk-1.key /tmp/disk-1.key \
  --disk-encryption-keys /tmp/disk-2.key <(pass my-disk-encryption-password) \
  --flake '.#your-host' \
  root@yourip
```

In the above example, replace `"my-super-safe-password"` with your actual
encryption password, and `my-disk-encryption-password` with the relevant entry
in your pass password store. Also, ensure to replace `'.#your-host'` and
`root@yourip` with your actual flake and IP address, respectively.

## Example: Using existing SSH host keys

If the system contains existing trusted `/etc/ssh/ssh_host_*` SSH host keys and
certificates, `nixos-anywhere` can copy them in case they are necessary during
installation and system activation.

```
nixos-anywhere --copy-host-keys --flake '.#your-host' root@yourip
```

This would copy `/etc/ssh/ssh_host_*` to `/mnt` after kexec but before
installation, ignoring files that already exist in destination.
