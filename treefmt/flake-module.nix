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
      programs.deno.enable = !pkgs.deno.meta.broken;
      programs.ruff.format = true;
      programs.ruff.check = true;
      settings.formatter.shellcheck.options = [ "-s" "bash" ];
    };
    formatter = config.treefmt.build.wrapper;
  };
}
