{ pkgs, ... }:
let
  # Granule isn't in nixpkgs; these are its official release binaries,
  # which exist only for x86_64 Linux and arm64 macOS.
  releases = {
    x86_64-linux = {
      asset = "linux_x86_64";
      hash = "sha256-ndT14Ewm5aoDMZI8Z7OS2Ldwl0RpPKil3PzO92+kXKo=";
    };
    aarch64-darwin = {
      asset = "macos_arm64";
      hash = "sha256-SSkaldNwkFGqbQ2DzR73dqPYEAngBsW0KSI6YHfb0Wg=";
      # This zip has no top-level directory; the Linux one does.
      sourceRoot = ".";
    };
  };
  release = releases.${pkgs.stdenv.hostPlatform.system} or null;
  granule = pkgs.stdenv.mkDerivation (
    {
      pname = "granule";
      version = "0.9.6.0";
      src = pkgs.fetchurl {
        url = "https://github.com/granule-project/granule/releases/download/v0.9.6.0/granule-v0.9.6.0-${release.asset}.zip";
        inherit (release) hash;
      };
      # The Linux binary needs patching to run here; the macOS one links
      # only against system libraries.
      nativeBuildInputs = [ pkgs.unzip ] ++ pkgs.lib.optional pkgs.stdenv.isLinux pkgs.autoPatchelfHook;
      buildInputs = pkgs.lib.optional pkgs.stdenv.isLinux pkgs.gmp;
      installPhase = "install -Dm755 gr $out/bin/gr";
    }
    // pkgs.lib.optionalAttrs (release ? sourceRoot) { inherit (release) sourceRoot; }
  );
in
{
  supported = release != null;
  packages = [
    granule
    pkgs.z3
  ];
  run = "gr --no-info --no-print-return-value expr.gr";
}
