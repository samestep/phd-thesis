# The PDF, buildable without flakes via `nix-build`. By default it uses the
# nixpkgs revision pinned in `flake.lock`, so it matches `nix build`.
{
  pkgs ?
    let
      nixpkgs = (builtins.fromJSON (builtins.readFile ./flake.lock)).nodes.nixpkgs.locked;
    in
    import (fetchTarball {
      url = "https://github.com/${nixpkgs.owner}/${nixpkgs.repo}/archive/${nixpkgs.rev}.tar.gz";
      sha256 = nixpkgs.narHash;
    }) { },
}:
let
  inherit (pkgs) lib;
  # Only what the document reads, so a non-flake build doesn't copy the
  # whole working tree (including untracked files) into the store.
  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./proposal.typ
      ./lib.typ
      ./refs.yml
      ./syntaxes/moss.sublime-syntax
      ./examples
      ./vendor
      ./postgres/NumAcc4.sql
    ];
  };
in
pkgs.runCommand "samestep-thesis" { buildInputs = [ pkgs.typst ]; } ''
  mkdir -p $out
  typst compile --root ${src} ${src}/proposal.typ $out/proposal.pdf
''
