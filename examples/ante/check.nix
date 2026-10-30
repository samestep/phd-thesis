{ pkgs, ... }:
{
  # nixpkgs' unstable Ante miscompiles this program on x86_64 with its default
  # LLVM backend: an `Expr` value passed through the pool's effect handler
  # comes back corrupted. Its C backend gets it right everywhere.
  packages = [ pkgs.ante ];
  run = "ante --backend c expr.an";
}
