{ pkgs, ... }:
let
  # Node's own type declarations aren't in Nixpkgs, and `tsc` needs them (and
  # the `undici-types` they import) to check an import from `node:async_hooks`.
  npm =
    name: version: hash:
    pkgs.fetchurl {
      url = "https://registry.npmjs.org/${name}/-/${baseNameOf name}-${version}.tgz";
      inherit hash;
    };
  types = {
    "@types/node" = npm "@types/node" "24.19.2" "sha512-93d49wCWJkCyN87MxLpNN6KXPCwFw7bVUg79mGUV1OS40JGWwVCr8n61DXCSqz7CV6/VfPkb7xec7uP2M+QHWQ==";
    undici-types = npm "undici-types" "7.24.6" "sha512-WRNW+sJgj5OBN4/0JpHFqtqzhpbnV0GuB+OozA9gCL7a993SmU+1JBZCzLNxYsbMfIeDL+lTsphD5jN5N+n0zg==";
  };
in
{
  packages = [
    pkgs.typescript
    pkgs.nodejs
  ];
  # Check with `tsc`, then let Node strip the types and run the same file.
  run = ''
    ${pkgs.lib.concatStrings (
      pkgs.lib.mapAttrsToList (name: tgz: ''
        mkdir -p node_modules/${name}
        tar -xzf ${tgz} -C node_modules/${name} --strip-components=1
      '') types
    )}
    tsc --noEmit --strict --erasableSyntaxOnly --types node main.mts >&2
    node main.mts
  '';
}
