{ pkgs, ... }:
{
  packages = [ pkgs.beamPackages.elixir ];
  # The build sandbox has no UTF-8 locale, which Elixir warns about; `+fnu`
  # tells the VM to treat file names as UTF-8 anyway.
  run = "ELIXIR_ERL_OPTIONS=+fnu elixir expr.exs";
}
