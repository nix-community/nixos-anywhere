{ stdenvNoCC
, makeWrapper
, lib
, openssh
, gitMinimal
, nix
, coreutils
, shellcheck
, rsync
, curl
}:
let
  runtimeDeps = [
    openssh
    gitMinimal # for git flakes
    rsync
    nix
    coreutils
    curl # when uploading tarballs
  ];
in
stdenvNoCC.mkDerivation {
  name = "nixos-remote";
  src = ./.;
  nativeBuildInputs = [
    makeWrapper
    shellcheck
  ];
  installPhase = ''
    install -D -m755 nixos-remote $out/bin/nixos-remote
    wrapProgram "$out/bin/nixos-remote" \
        --prefix PATH : "${lib.makeBinPath runtimeDeps}"
  '';

  doCheck = true;
  checkPhase = ''
    shellcheck ./nixos-remote
  '';
}
