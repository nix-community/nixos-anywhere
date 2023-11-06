{ stdenv
, openssh
, gitMinimal
, rsync
, nixVersions
, nix
, coreutils
, curl
, gnugrep
, gawk
, findutils
, gnused
, terraform-docs
, lib
, makeWrapper
, mkShellNoCC
}:
let
  # TODO: add this to nixpkgs
  rsync' = rsync.overrideAttrs (old: {
    # https://github.com/WayneD/rsync/issues/511#issuecomment-1774612577
    patches = [ ./rsync-fortified-strlcpy-fix.patch ];
  });
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
    rsync' # used to upload extra-files
  ];
in
stdenv.mkDerivation {
  pname = "nixos-anywhere";
  version = "1.0.0";
  src = ./..;
  nativeBuildInputs = [ makeWrapper ];
  installPhase = ''
    install -D -m 0755 src/nixos-anywhere.sh $out/bin/nixos-anywhere

    # We prefer the system's openssh over our own, since it might come with features not present in ours:
    # https://github.com/numtide/nixos-anywhere/issues/62
    #
    # We also prefer system rsync to prevent crashes between rsync and ssh.
    wrapProgram $out/bin/nixos-anywhere \
      --prefix PATH : ${lib.makeBinPath runtimeDeps} --suffix PATH : ${lib.makeBinPath [ openssh ]}
  '';

  # Dependencies for our devshell
  passthru.devShell = mkShellNoCC {
    packages = runtimeDeps ++ [ openssh terraform-docs ];
  };

  meta = with lib; {
    description = "Install nixos everywhere via ssh";
    homepage = "https://github.com/numtide/nixos-anywhere";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
