{ pkgs, inputs, ... }:
{
  # Effekt isn't in nixpkgs; its official release (the `effekt` input) is a
  # self-running JAR.
  packages = [
    pkgs.jdk
    pkgs.nodejs
  ];
  run = ''
    java -Xss32m -jar ${inputs.effekt}/bin/effekt --build main.effekt >&2
    node -e "require('./out/main.js').main()"
  '';
}
