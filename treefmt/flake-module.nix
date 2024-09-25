{ inputs, ... }: {
  imports = [
    inputs.treefmt-nix.flakeModule
  ];
  perSystem = { config, lib, pkgs, ... }: {
    treefmt = {
      projectRootFile = "flake.nix";
      programs.mdsh.enable = true;
      programs.nixpkgs-fmt.enable = true;
      programs.shellcheck.enable = true;
      programs.shfmt.enable = true;
      programs.deno.enable = true;
      settings.formatter.shellcheck.options = [ "-s" "bash" ];
      settings.formatter.python = {
        command = "sh";
        options = [
          "-eucx"
          ''
            ${lib.getExe pkgs.ruff} --fix "$@"
            ${lib.getExe pkgs.ruff} format "$@"
          ''
          "--" # this argument is ignored by bash
        ];
        includes = [ "*.py" ];
      };
    };
    formatter = config.treefmt.build.wrapper;
  };
}
