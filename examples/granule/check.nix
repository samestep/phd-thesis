{ pkgs, ... }:
let
  # Granule isn't in nixpkgs; this is its official Linux release, patched to run here.
  granule = pkgs.stdenv.mkDerivation {
    pname = "granule";
    version = "0.9.6.0";
    src = pkgs.fetchurl {
      url = "https://github.com/granule-project/granule/releases/download/v0.9.6.0/granule-v0.9.6.0-linux_x86_64.zip";
      hash = "sha256-ndT14Ewm5aoDMZI8Z7OS2Ldwl0RpPKil3PzO92+kXKo=";
    };
    nativeBuildInputs = [
      pkgs.unzip
      pkgs.autoPatchelfHook
    ];
    buildInputs = [ pkgs.gmp ];
    installPhase = "install -Dm755 gr $out/bin/gr";
  };
in
{
  supported = pkgs.stdenv.hostPlatform.system == "x86_64-linux";
  packages = [
    granule
    pkgs.z3
  ];
  run = "gr --no-info --no-print-return-value expr.gr";
}
