{ pkgs, ... }:
{
  # nixpkgs' unstable Ante miscompiles these programs with its default LLVM
  # backend: an `Expr` passed through the pool's effect handler comes back
  # corrupted (the concrete one on x86_64, the generic one everywhere). Its C
  # backend gets them right.
  packages = [ pkgs.ante ];
  run = "ante --backend c expr.an";
}
