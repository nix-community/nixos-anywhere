{ stdenv
, openssh
, gitMinimal
, nixVersions
, nix
, coreutils
, curl
, gnugrep
, gnutar
, gawk
, findutils
, gnused
, sshpass
, terraform-docs
, lib
, makeWrapper
, mkShellNoCC
}:
let
  runtimeDeps = [
    gitMinimal # for git flakes
    # pinned because nix-copy-closure hangs if ControlPath provided for SSH: https://github.com/NixOS/nix/issues/8480
    (if lib.versionAtLeast nix.version "2.16" then nix else nixVersions.nix_2_16)
    coreutils
    curl # when uploading tarballs
    gnugrep
    gawk
    findutils
    gnused # needed by ssh-copy-id
    sshpass # used to provide password for ssh-copy-id
    gnutar # used to upload extra-files
  ];
in
stdenv.mkDerivation {
  pname = "nixos-anywhere";
  version = "1.11.0";
  src = ./..;
  nativeBuildInputs = [ makeWrapper ];
  installPhase = ''
    install -D --target-directory=$out/libexec/nixos-anywhere/ -m 0755 src/*.sh

    # We prefer the system's openssh over our own, since it might come with features not present in ours:
    # https://github.com/nix-community/nixos-anywhere/issues/62
    makeShellWrapper $out/libexec/nixos-anywhere/nixos-anywhere.sh $out/bin/nixos-anywhere \
      --prefix PATH : ${lib.makeBinPath runtimeDeps} --suffix PATH : ${lib.makeBinPath [ openssh ]}
  '';

  # Dependencies for our devshell
  passthru.devShell = mkShellNoCC {
    packages = runtimeDeps ++ [ openssh terraform-docs ];
  };

  meta = with lib; {
    description = "Install nixos everywhere via ssh";
    homepage = "https://github.com/nix-community/nixos-anywhere";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
