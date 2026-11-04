{ pkgs, inputs, ... }:
let
  # `tsc` needs Node's own type declarations (and the `undici-types` they
  # import) to check an import from `node:async_hooks`.
  types = {
    "@types/node" = inputs.types-node;
    undici-types = inputs.undici-types;
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
      pkgs.lib.mapAttrsToList (name: src: ''
        mkdir -p node_modules/${name}
        cp -r ${src}/. node_modules/${name}
      '') types
    )}
    tsc --noEmit --strict --erasableSyntaxOnly --types node main.mts >&2
    node main.mts
  '';
}
