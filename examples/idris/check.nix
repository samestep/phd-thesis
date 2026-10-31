{ pkgs, ... }:
{
  # On macOS the launcher Idris generates resolves its own path with zsh.
  packages = [
    pkgs.idris2
    pkgs.zsh
  ];
  run = "idris2 Main.idr -o main >/dev/null && build/exec/main";
}
