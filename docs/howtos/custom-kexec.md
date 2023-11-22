# Using your own kexec image

By default, `nixos-anywhere` downloads the kexec image from the
[NixOS images repository](https://github.com/nix-community/nixos-images#kexec-tarballs).

However, you can provide your own `kexec` image file if you need to use a
different one. This is particularly useful for architectures other than `x86_64`
and `aarch64`, since they don't have a pre-build image.

To do this, use the `--kexec` command line switch followed by the path to your
image file. The image will be uploaded prior to execution.

Here's an example command that demonstrates how to use a custom kexec image with
`nixos-anywhere`:

```
nix run github:nix-community/nixos-anywhere -- \
  --kexec "$(nix build --print-out-paths github:nix-community/nixos-images#packages.aarch64-linux.kexec-installer-nixos-unstable-noninteractive)/nixos-kexec-installer-noninteractive-aarch64-linux.tar.gz" \
  --flake 'github:your-user/your-repo#your-system' \
  root@yourip
```

Make sure to replace `github:your-user/your-repo#your-system` with the
appropriate Flake URL representing your NixOS configuration.

The example above assumes that your local machine can build for aarch64 in one
of the following ways:

- Natively

- Through a remote builder

- By emulating the architecture with qemu using the following NixOS
  configuration:

```nix
{
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
}
```
