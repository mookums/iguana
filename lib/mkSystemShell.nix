{ nixpkgs, inputs, zigPkgs, zigStable }:
system:
{ zigVersion ? zigStable, extraPackages ? [ ], withZls ? false }:
let

  getZls = version:
    {
      "0.11.0" = inputs.zls-0-11;
      "0.12.0" = inputs.zls-0-12;
      "0.13.0" = inputs.zls-0-13;
      "master" = inputs.zls-master;
    }.${version} or inputs.zls-0-13;

  mkZigOverlay = import ./mkZigOverlay.nix { inherit zigPkgs zigVersion; };

  zlsOverlay = if withZls then
    final: prev: {
      zls = (getZls zigVersion).packages.${prev.system}.zls.overrideAttrs
        (old: { nativeBuildInputs = [ final.zig ]; });
    }
  else
    _: _: { };

  pkgs = import nixpkgs {
    inherit system;
    overlays = [ (mkZigOverlay zigVersion) zlsOverlay ];
  };

  basePackages = [ pkgs.zig ] ++ (if withZls then [ pkgs.zls ] else [ ])
    ++ extraPackages;

in pkgs.mkShell { packages = basePackages; }
