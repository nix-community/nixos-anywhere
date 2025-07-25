{ inputs, ... }: {
  imports = [
    inputs.treefmt-nix.flakeModule
  ];
  perSystem = { config, pkgs, ... }: {
    treefmt = {
      projectRootFile = "flake.nix";
      programs.nixpkgs-fmt.enable = true;
      programs.shellcheck.enable = true;
      programs.shfmt.enable = true;
      programs.terraform.enable = true;
      programs.deno.enable = !pkgs.deno.meta.broken;
      settings.formatter.shellcheck.options = [ "-s" "bash" ];
    };
    formatter = config.treefmt.build.wrapper;
  };
}
