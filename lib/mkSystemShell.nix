{
  nixpkgs,
  inputs,
  zigPkgs,
  zigStable,
}:
system:
{
  zigVersion ? zigStable,
  extraPackages ? [ ],
  withZls ? false,
}:
let

  mkZigOverlay = import ./mkZigOverlay.nix { inherit zigPkgs; };
  mkZlsOverlay = import ./mkZlsOverlay.nix { inherit zigPkgs; };

  pkgs = import nixpkgs {
    inherit system;
    overlays = [
      (mkZigOverlay zigVersion)
      (mkZlsOverlay zigVersion)
    ];
  };

  basePackages = [ pkgs.zig ] ++ (if withZls then [ pkgs.zls ] else [ ]) ++ extraPackages;
in
pkgs.mkShell { packages = basePackages; }
