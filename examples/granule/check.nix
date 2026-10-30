{ pkgs, inputs, ... }:
let
  # Granule isn't in nixpkgs; these inputs are its official release
  # binaries, which exist only for x86_64 Linux and arm64 macOS.
  release =
    {
      x86_64-linux = inputs.granule-linux-x86_64;
      aarch64-darwin = inputs.granule-macos-arm64;
    }
    .${pkgs.stdenv.hostPlatform.system} or null;
  granule = pkgs.stdenv.mkDerivation {
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
  supported = release != null;
  packages = [
    granule
    pkgs.z3
  ];
  run = "gr --no-info --no-print-return-value expr.gr";
}
