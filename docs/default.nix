{ lib
, runCommand
, writeShellScriptBin
, coreutils
, mdbook
}:
runCommand "nixos-anywhere-docs"
{
  passthru.serve = writeShellScriptBin "serve" ''
    set -euo pipefail
    cd docs
    workdir=$(${coreutils}/bin/mktemp -d)
    trap 'rm -rf "$workdir"' EXIT
    ${mdbook}/bin/mdbook serve --dest-dir "$workdir"
  '';
}
  ''
    cp -r ${lib.cleanSource ./.}/* .
    ${mdbook}/bin/mdbook build --dest-dir "$out"
  ''
