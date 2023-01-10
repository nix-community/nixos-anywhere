{ writeShellApplication
, openssh
, gitMinimal
, rsync
, nix
, coreutils
, curl
}:
writeShellApplication {
  name = "nixos-remote";
  text = builtins.readFile ./nixos-remote.sh;
  runtimeInputs = [
    openssh
    gitMinimal # for git flakes
    rsync
    nix
    coreutils
    curl # when uploading tarballs
  ];
}
