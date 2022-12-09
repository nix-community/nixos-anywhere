{
  description = "A universal nixos installer, just needs ssh access to the target system";

  inputs.nixpkgs.url = "nixpkgs";
  inputs.disko.url = "github:nix-community/disko/master";
  inputs.disko.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs, disko, ... }: {
    checks.x86_64-linux = let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in {
      from-nixos = import ./tests/from-nixos.nix {
        inherit pkgs;
        disko = disko.nixosModules.disko;
        makeTest = import (pkgs.path + "/nixos/tests/make-test-python.nix");
        eval-config = import (pkgs.path + "/nixos/lib/eval-config.nix");
      };
    };
  };
}
