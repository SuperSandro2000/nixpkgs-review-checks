{ pkgs ? import <nixpkgs> {
    overlays = [
      (final: prev: {
        nixpkgs-hammering = (import (
          let
            lock = builtins.fromJSON (builtins.readFile ./flake.lock);
          in
          fetchTarball {
            url = "https://github.com/jtojnar/nixpkgs-hammering/archive/${lock.nodes.nixpkgs-hammering.locked.rev}.tar.gz";
            sha256 = lock.nodes.nixpkgs-hammering.locked.narHash;
          }
        )).packages."${final.system}".default;
      })
    ];
  }
, src ? ./.
}:

with pkgs;

stdenv.mkDerivation rec {
  name = "nixpkgs-review-checks";

  inherit src;

  nativeBuildInputs = [
    makeWrapper
  ];

  buildInputs = [
    bc
    bloaty
    coreutils
    curl
    gawk
    gh
    gnused
    hydra-check
    mdcat
    nix
    nixpkgs-hammering
    nixpkgs-review
    jq
    pup
    python3Packages.ansi2html
    ripgrep
    savepagenow
  ];

  installPhase = ''
    install -Dm755 nixpkgs-review-checks -t $out/bin
    install -Dm755 nixpkgs-review-checks-hook -t $out/etc/profile.d
    install -Dm755 ofborg.graphql -t $out/share/nixpkgs-review-checks
    wrapProgram $out/bin/nixpkgs-review-checks \
      --prefix PATH : ${lib.makeBinPath buildInputs} \
      --set NIXPKGS_REVIEW_CHECKS_GRAPHQL_FILE $out/share/nixpkgs-review-checks/ofborg.graphql
  '';

  passthru.env = buildEnv { inherit name; paths = buildInputs; };
}
