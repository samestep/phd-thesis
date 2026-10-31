{ pkgs, inputs, ... }:
let
  inherit (pkgs.stdenv.hostPlatform) system;
  # Granule isn't in nixpkgs. Its official release binaries exist only for
  # x86_64 Linux and arm64 macOS; elsewhere, its own flake builds it from
  # source.
  release =
    {
      x86_64-linux = inputs.granule-linux-x86_64;
      aarch64-darwin = inputs.granule-macos-arm64;
    }
    .${system} or null;
  granule =
    if release == null then
      inputs.granule.packages.${system}.granule-interpreter
    else
      pkgs.stdenv.mkDerivation {
        pname = "granule";
        version = "0.9.6.0";
        src = release;
        # The Linux binary needs patching to run here; the macOS one links
        # only against system libraries.
        nativeBuildInputs = pkgs.lib.optional pkgs.stdenv.hostPlatform.isLinux pkgs.autoPatchelfHook;
        buildInputs = pkgs.lib.optional pkgs.stdenv.hostPlatform.isLinux pkgs.gmp;
        installPhase = "install -Dm755 gr $out/bin/gr";
      };
in
{
  packages = [
    granule
    pkgs.z3
  ];
  run = "gr --no-info --no-print-return-value expr.gr";
}
