{ pkgs, ... }:
{
  # nixpkgs' unstable Ante miscompiles this program on x86_64: an `Expr`
  # value passed through the pool's effect handler comes back corrupted.
  # It runs correctly on aarch64 (Linux and macOS).
  supported = pkgs.stdenv.hostPlatform.system != "x86_64-linux";
  packages = [ pkgs.ante ];
  run = "ante expr.an";
}
