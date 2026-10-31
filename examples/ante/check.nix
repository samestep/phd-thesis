{ pkgs, ... }:
{
  # nixpkgs' unstable Ante miscompiles these programs with its default LLVM
  # backend, corrupting `Main` values (the concrete one on x86_64; the generic
  # and tree ones everywhere). Its C backend gets them right.
  packages = [ pkgs.ante ];
  run = "ante --backend c main.an";
}
