{ pkgs ? import <nixpkgs> { } }:

with pkgs;

mkShellNoCC {
  nativeBuildInputs = [
    bc
    bloaty
    coreutils
    curl
    gawk
    gh
    gnused
    hydra-check
    mdcat
    jq
    pup
    python3Packages.ansi2html
    ripgrep
    savepagenow
  ];
}
