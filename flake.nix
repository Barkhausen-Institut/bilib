####    ############    Copyright (C) 2025 Mattis Hasler, Barkhausen Institut
####    ############    
####                    This source describes Open Hardware and is licensed under the
####                    CERN-OHL-W v2 (https://cern.ch/cern-ohl)
############    ####    
############    ####    
####    ####    ####    
####    ####    ####    
############            Authors:
############            Mattis Hasler (mattis.hasler@barkhauseninstitut.org)

{
  description = "Barkhauseninstitut EDA base library";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs;
    nixpkgs2211.url = github:NixOs/nixpkgs/22.11;
    flake-utils.url = "github:numtide/flake-utils";
    roadrunner.url = git+ssh://git@gitlab.barkhauseninstitut.org/mattis.hasler/roadrunner;
};

  outputs = { self, nixpkgs, flake-utils, roadrunner, nixpkgs2211 }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        pkgs2211 = nixpkgs2211.legacyPackages.${system};
        rr = roadrunner.packages.${system}.roadrunner;
      in
      {
        devShell = import nix/shell.nix {
          inherit pkgs rr pkgs2211;
        };
      }
    );
}
