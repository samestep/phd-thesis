# PostgreSQL 11.22, the last release of the last version with the
# schoolbook variance formula, from its release tarball (nixpkgs has
# dropped version 11). Just the server and psql: no readline, zlib or SSL.
{ pkgs, src }:
pkgs.stdenv.mkDerivation {
  pname = "postgresql";
  version = "11.22";
  inherit src;
  configureFlags = [
    "--without-readline"
    "--without-zlib"
  ];
  # C99, as it was written for: GCC 15 and later default to C23, where
  # `bool` is a keyword its headers can't define.
  env.NIX_CFLAGS_COMPILE = "-std=gnu99";
  enableParallelBuilding = true;
}
