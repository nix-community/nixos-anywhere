{ mdbook, stdenv, writeShellScriptBin }:

stdenv.mkDerivation {
  name = "nixos-remote-docs";
  buildInputs = [ mdbook ];
  src = ./.;
  buildPhase = "mdbook build";
  installPhase = ''
    mv book $out
  '';

  # > nix run .#docs.serve
  passthru.serve = writeShellScriptBin "serve" ''
    cd docs
    ${mdbook}/bin/mdbook serve
  '';
}
