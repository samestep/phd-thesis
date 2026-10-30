{ pkgs, ... }:
{
  # The official binaries: nixpkgs' source build of `julia` fails to link
  # its bundled LLVM on aarch64-linux.
  packages = [ pkgs.julia-bin ];
  run = "julia --startup-file=no expr.jl";
}
