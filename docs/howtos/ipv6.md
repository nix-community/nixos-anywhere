# NixOS-anywhere on Ipv6-only targets

As GitHub engineers still haven't enabled the ipv6 switch, the kexec image
hosted on GitHub, cannot be used unfortunally on ipv6-only hosts. However it is
possible to use an ipv6 proxy for github content like that:

```
nixos-anywhere \
  --kexec https://gh-v6.com/nix-community/nixos-images/releases/download/nixos-unstable/nixos-kexec-installer-noninteractive-x86_64-linux.tar.gz \
...
```

This proxy is hosted by (numtide)[https://numtide.com/]. It also works for ipv4.

Alternativly it is also possible to reference a local file:

```
nixos-anywhere \
  --kexec ./nixos-kexec-installer-noninteractive-x86_64-linux.tar.gz \
...
```

This tarball will be than uploaded via sftp to the target.
