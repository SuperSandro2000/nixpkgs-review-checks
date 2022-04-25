{ pkgs ? import <nixpkgs> { }
, src ? ./.
}:

with pkgs;

let
  nixpkgs-hammering = import (
    let
      lock = builtins.fromJSON (builtins.readFile ./flake.lock); in
    fetchTarball {
      url = "https://github.com/jtojnar/nixpkgs-hammering/archive/${lock.nodes.nixpkgs-hammering.locked.rev}.tar.gz";
      sha256 = lock.nodes.nixpkgs-hammering.locked.narHash;
    }
  );
in
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
    wrapProgram $out/bin/nixpkgs-review-checks \
      --prefix PATH : ${lib.makeBinPath buildInputs}
    install -Dm755 nixpkgs-review-checks-hook -t $out/etc/profile.d
  '';

  passthru.env = buildEnv { inherit name; paths = buildInputs; };
}
