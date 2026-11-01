{ pkgs, ... }:
let
  # Bumpalo, built with plain `rustc` as the other examples are: with only
  # its `collections` feature it has no dependencies, so no Cargo.
  bumpalo = pkgs.fetchCrate {
    pname = "bumpalo";
    version = "3.20.3";
    hash = "sha256-Jbohw96ToBr4fb0BfWwgGCuXccnqdE+LKCV9e68DPLU=";
  };
in
{
  packages = [ pkgs.rustc ];
  run = ''
    rustc -O --edition 2021 --crate-type rlib --crate-name bumpalo --cfg 'feature="collections"' \
      --cap-lints allow ${bumpalo}/src/lib.rs -o libbumpalo.rlib
    rustc -O --edition 2021 --extern bumpalo=libbumpalo.rlib main.rs -o main && ./main
  '';
}
