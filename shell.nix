{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShellNoCC {
  buildInputs = [
    (import ./. { }).passthru.env
  ];
}
