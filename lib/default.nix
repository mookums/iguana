{
  nixpkgs,
  inputs,
  zigPkgs,
  zigStable,
}:
system:
let
  zigSystem = import ./toZigSystem.nix {
    inherit (nixpkgs) lib;
  } system;

  mkZigOverlay = import ./mkZigOverlay.nix {
    inherit zigPkgs;
  };

  mkZlsOverlay = import ./mkZlsOverlay.nix {
    inherit zigPkgs;
  };

  mkShell = import ./mkSystemShell.nix {
    inherit
      nixpkgs
      inputs
      zigPkgs
      zigStable
      ;
  } system;

  mkZigPackage = import ./mkZigPackage.nix {
    inherit
      nixpkgs
      inputs
      zigSystem
      zigPkgs
      zigStable
      ;
  } system;
in
{
  inherit mkZigOverlay;
  inherit mkZlsOverlay;
  inherit mkShell;
  inherit mkZigPackage;
}
