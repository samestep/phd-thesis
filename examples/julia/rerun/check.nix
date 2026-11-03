{ pkgs, ... }:
{
  # With DoubleFloats.jl, from the registry by way of nixpkgs.
  packages = [ (pkgs.julia-bin.withPackages [ "DoubleFloats" ]) ];
  run = "julia --startup-file=no main.jl";
}
