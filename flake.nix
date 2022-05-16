{
  description = "Add additional checks and more information from build logs and outputs to the reports generated by nixpkgs-review.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    nixpkgs-hammering = {
      url = "github:jtojnar/nixpkgs-hammering";
      inputs = {
        naersk.follows = "naersk";
        nixpkgs.follows = "nixpkgs";
        utils.follows = "flake-utils";
      };
    };
    flake-utils.url = "github:numtide/flake-utils";
    naersk = {
      url = "github:nix-community/naersk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, flake-utils, naersk, nixpkgs, nixpkgs-hammering }:
    flake-utils.lib.eachDefaultSystem (system: {
      packages.nixpkgs-review-checks = nixpkgs.legacyPackages.${system}.callPackage self {
        src = self;
        pkgs = import nixpkgs {
          overlays = [
            (prev: final: {
              nixpkgs-hammering = nixpkgs-hammering.packages."${system}".default;
            })
          ];
          inherit system;
        };
        inherit system;
      };
      defaultPackage = self.packages.${system}.nixpkgs-review-checks;
    });
}
