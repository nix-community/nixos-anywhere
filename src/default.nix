{ writeShellApplication
, openssh
, gitMinimal
, rsync
, nix
, coreutils
, curl
, gnugrep
, findutils
, gnused
, lib
, mkShellNoCC
}:
let
  runtimeInputs = [
    gitMinimal # for git flakes
    rsync
    nix
    coreutils
    curl # when uploading tarballs
    gnugrep
    findutils
    gnused # needed by ssh-copy-id
  ];
in
(writeShellApplication {
  name = "nixos-anywhere";
  # We prefer the system's openssh over our own, since it might come with features not present in ours:
  # https://github.com/numtide/nixos-anywhere/issues/62
  text = ''
    export PATH=$PATH:${lib.getBin openssh}
    ${builtins.readFile ./nixos-anywhere.sh}
  '';
  inherit runtimeInputs;
}) // {
  # Dependencies for our devshell
  devShell = mkShellNoCC {
    packages = runtimeInputs ++ [ openssh ];
  };
}
