{ pkgs, inputs, ... }:
{
  packages = [ pkgs.rustc ];
  # Bumpalo, built with plain `rustc` as the other examples are: with only its
  # `collections` feature it has no dependencies, so no Cargo.
  run = ''
    rustc -O --edition 2021 --crate-type rlib --crate-name bumpalo --cfg 'feature="collections"' \
      --cap-lints allow ${inputs.bumpalo}/src/lib.rs -o libbumpalo.rlib
    rustc -O --edition 2021 --extern bumpalo=libbumpalo.rlib main.rs -o main && ./main
  '';
}
