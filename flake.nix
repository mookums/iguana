{
  description = "A Nix library for building Zig projects.";

  inputs = {
    zigPkgs.url = "github:mookums/zig-overlay";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      zigPkgs,
      flake-utils,
      ...
    }:
    let
      zigStable = "0_14_0";
      zigSystems = builtins.attrNames zigPkgs.packages;

      mkSystemLib = import ./lib {
        inherit
          nixpkgs
          inputs
          zigPkgs
          zigStable
          ;
      };
    in
    (flake-utils.lib.eachSystem zigSystems (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        lib = mkSystemLib system;
      in
      {
        inherit lib;

        # For working on Iguana.
        devShells.default = lib.mkShell {
          withZls = true;
          extraPackages = with pkgs; [
            python3
            python312Packages.python-lsp-server
          ];
        };
      }
    ));
}
