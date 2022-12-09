{ stdenvNoCC, makeWrapper, lib, openssh, git, nix, coreutils }:
let
  runtimeDeps = [
    openssh
    git # for git flakes
    nix
    coreutils
  ];
in
stdenvNoCC.mkDerivation {
  name = "nixos-remote";
  src = ./.;
  nativeBuildInputs = [
    makeWrapper
  ];
  installPhase = ''
    install -D -m755 nixos-remote $out/bin/nixos-remote
    wrapProgram "$out/bin/nixos-remote" \
        --prefix PATH : "${lib.makeBinPath runtimeDeps}"
  '';
}
