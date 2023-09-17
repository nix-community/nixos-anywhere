{ inputs, ... }: {
  imports = [
    inputs.treefmt-nix.flakeModule
  ];
  perSystem = { config, ... }: {
    treefmt = {
      projectRootFile = "flake.nix";
      programs.mdsh.enable = true;
      programs.nixpkgs-fmt.enable = true;
      programs.shellcheck.enable = true;
      programs.shfmt.enable = true;
      programs.deno.enable = true;
      settings.formatter.shellcheck.options = [ "-s" "bash" ];
    };
    formatter = config.treefmt.build.wrapper;
  };
}
