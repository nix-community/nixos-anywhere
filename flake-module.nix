{
  perSystem = { pkgs, lib, ... }: {
    packages.docs = pkgs.runCommand "nixos-anywhere-docs"
      {
        passthru.serve = pkgs.writeShellScriptBin "serve" ''
          set -euo pipefail
          cd docs
          workdir=$(${pkgs.coreutils}/bin/mktemp -d)
          trap 'rm -rf "$workdir"' EXIT
          ${pkgs.mdbook}/bin/mdbook serve --dest-dir "$workdir"
        '';
      }
      ''
        cp -r ${lib.cleanSource ./.}/* .
        ${pkgs.mdbook}/bin/mdbook build --dest-dir "$out"
      '';
  };
}
