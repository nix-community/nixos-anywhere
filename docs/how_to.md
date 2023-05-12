# How To Guide: nixos-anywhere

## Contents

[Installing on a machine with no operating system](#installing-on-a-machine-with-no-operating-system)

[Using your own kexec image](#using-your-own-kexec-image)

[Using nixos-anywhere without flakes](#using-nixos-anywhere-without-flakes)

TODO: Add more topics

## Installing on a machine with no operating system

TODO: Still to be documented

Include: 

`nixos-anywhere` can detect a nixos installer if it contains the identifier `VARIANT=installer` in its `/etc/os-release` file. This is the case for the nixos-unstable installer and will be also part of nixos 23.05. If an installer is detected `nixos-anywhere` will not try to kexec into its own image.

## Using your own kexec image

By default `nixos-anywhere` will download the kexec image from [here](https://github.com/nix-community/nixos-images#kexec-tarballs). It is also possible to provide your own by using the command line switch `--kexec` to specify the image file. The image will then be uploaded prior to executing.

```
nixos-anywhere \
  --kexec "$(nix build --print-out-paths github:nix-community/nixos-images#packages.x86_64-linux.kexec-installer-noninteractive-nixos-unstable)/nixos-kexec-installer-noninteractive-x86_64-linux.tar.gz" \
  --flake 'github:your-user/your-repo#your-system' \
  root@yourip
```

This is particularly useful for distributions like aarch64-linux, where there is no pre-build image. The following example assumes that your local machine can build for aarch64-linux either natively or through a remote builder

## Using nixos-anywhere without flakes

TODO: Add content

```

```


