# NixOS-anywhere on IPv6-only targets

As GitHub engineers still haven't enabled the IPv6 switch, the kexec image
hosted on GitHub, cannot be used unfortunately on IPv6-only hosts. However it is
possible to use an IPv6 proxy for GitHub content like that:

```
nixos-anywhere \
  --kexec https://gh-v6.com/nix-community/nixos-images/releases/download/nixos-unstable/nixos-kexec-installer-noninteractive-x86_64-linux.tar.gz \
...
```

This proxy is hosted by [numtide](https://numtide.com/). It also works for IPv4.

Alternatively it is also possible to reference a local file:

```
nixos-anywhere \
  --kexec ./nixos-kexec-installer-noninteractive-x86_64-linux.tar.gz \
...
```

This tarball will be then uploaded via sftp to the target.
