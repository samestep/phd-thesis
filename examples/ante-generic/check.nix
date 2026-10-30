{ pkgs, ... }:
{
  # nixpkgs' unstable Ante miscompiles this program with its default LLVM
  # backend (on every platform): an `Expr r` passed through the effect handler
  # comes back with garbage in a literal's upper bytes. Its C backend gets it
  # right.
  packages = [ pkgs.ante ];
  run = "ante --backend c expr.an";
}
