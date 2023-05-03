# nixos-anywhere - install nixos everywhere via ssh

<img src="https://raw.githubusercontent.com/numtide/nixos-anywhere/main/docs/logo.png" width="256" height="256">

nixos-anywhere (formally known as nixos-remote) makes it possible to install
nixos from Linux machines reachable via ssh. Under the hood uses a
[kexec image](https://github.com/nix-community/nixos-images#kexec-tarballs) to
boot into a NixOS installer from a running Linux system. It then uses
[disko](https://github.com/nix-community/disko) to partition and format the
disks on the target system before it installs the user provided nixos
configuration.

## Requirements

`nixos-anywhere` can detect nixos installer if those contain the identifier
`VARIANT=installer` in their `/etc/os-release` file. This is the case for the
nixos-unstable installer and will be also part of nixos 23.05. If installer is
detected `nixos-anywhere` will not try to kexec into its own image.

If your system is not booted into a nixos installer than the following
requirements apply for kexec to succeed:

- x86_64 Linux system with kexec support (most x86_64 machine do have kexec
  support) or you have to provide your own
  [image](https://github.com/numtide/nixos-anywhere#using-your-own-kexec-image)
- At least 2.5GB RAM (swap does not count). If you do not have enough RAM you
  will see failures unpacking the initrd), this is because kexec needs to load
  the whole nixos into memory.

## Usage

Needs a repo with your configurations with flakes. For a minimal example
checkout https://github.com/numtide/nixos-anywhere-examples.

Your NixOS configuration will also need a
[disko](https://github.com/nix-community/disko) configuration as we can see in
our
[example](https://github.com/numtide/nixos-anywhere-examples/blob/9768e438b1467ec55d42e096860e7199bd1ef43d/flake.nix#L15-L19)

Afterwards you can just run:

```
nix run github:numtide/nixos-anywhere -- root@yourip --flake github:your-user/your-repo#your-system
```

The parameter passed to `--flake` should point to your nixos configuration
exposed in your flake (`nixosConfigurations.your-system` in the example above).

`nixos-anywhere --help`

```shell
Usage: nixos-anywhere [options] ssh-host

Options:

* -f, --flake flake
  set the flake to install the system from
* -L, --print-build-logs
  print full build logs
* -s, --store-paths
  set the store paths to the disko-script and nixos-system directly
  if this is give, flake is not needed
* --no-reboot
  do not reboot after installation, allowing further customization of the target installation.
* --kexec url
  use another kexec tarball to bootstrap NixOS
* --stop-after-disko
  exit after disko formating, you can then proceed to install manually or some other way
* --extra-files files
  files to copy into the new nixos installation
* --disk-encryption-keys remote_path local_path
  copy the contents of the file or pipe in local_path to remote_path in the installer environment,
  after kexec but before installation. Can be repeated.
* --no-substitute-on-destination
  disable passing --substitute-on-destination to nix-copy
* --debug
  enable debug output
* --option KEY VALUE
  nix option to pass to every nix related command
* --from store-uri
  URL of the source Nix store to copy the nixos and disko closure from
```

## Using your own kexec image

By default `nixos-anywhere` will download the kexec image from
[here](https://github.com/nix-community/nixos-images#kexec-tarballs). It is also
possible to provide your own by providing a file to `--kexec`. The image will
than uploaded prior to executing.

```shell
nixos-anywhere \
  --kexec "$(nix build --print-out-paths github:nix-community/nixos-images#packages.x86_64-linux.kexec-installer-nixos-unstable)/nixos-kexec-installer-x86_64-linux.tar.gz" \
  --flake 'github:your-user/your-repo#your-system' \
  root@yourip
```

`--kexec` can be useful for example for aarch64-linux, where there is no
pre-build image. The following example assumes that your local machine can build
for aarch64-linux either natively or through a remote builder

```shell
nixos-anywhere \
  --kexec "$(nix build --print-out-paths github:nix-community/nixos-images#packages.aarch64-linux.kexec-installer-nixos-unstable)/nixos-kexec-installer-aarch64-linux.tar.gz" \
  --flake 'your-flake#your-system' \
  root@yourip
```

## Developer guide

To run `nixos-anywhere` from the repo:

```console
nix run . -- --help
```

To format the code

```console
nix fmt
```

# Further Reading 

@tfc has written a walkthrough on how use nixos-anywhere to bootstrap hetzner cloud servers as well as dedicated ones on his blog: https://galowicz.de/2023/04/05/single-command-server-bootstrap/
