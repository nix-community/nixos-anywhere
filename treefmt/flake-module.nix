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
      settings.formatter.shfmt.excludes = [ "src/nixos-anywhere.sh" ];
    };
    formatter = config.treefmt.build.wrapper;
  };
}
