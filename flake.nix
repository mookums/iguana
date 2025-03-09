{
  description = "A Nix library for building Zig projects.";

  inputs = {
    zigPkgs.url = "github:mitchellh/zig-overlay";
    flake-utils.url = "github:numtide/flake-utils";

    # ZLS versions
    # Not sure how else to do this and stay pure.
    zls-0-13.url = "github:zigtools/zls/0.13.0";
    zls-0-14.url = "github:zigtools/zls/0.14.0";
    zls-master.url = "github:zigtools/zls/master";
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
      zigStable = "0.14.0";
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
