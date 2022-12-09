{ stdenvNoCC }:
stdenvNoCC.mkDerivation {
  name = "nixos-remote";
  src = ./.;
  installPhase = ''
    install -D -m755 nixos-remote $out/bin/nixos-remote
  '';
}
