{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        packages.default = pkgs.runCommand "samestep-thesis" { buildInputs = [ pkgs.typst ]; } ''
          mkdir -p $out
          typst compile ${./proposal.typ} $out/proposal.pdf
        '';
        devShells.default = pkgs.mkShellNoCC {
          packages = [
            pkgs.typst
          ];
        };
      }
    );
}
