{
  description = "";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-24.11";
    iguana.url = "github:mookums/iguana";
  };

  outputs = { self, nixpkgs, iguana, ... }:
    let
      system = "x86_64-linux";
      iguanaLib = iguana.lib.${system};
    in {
      packages.${system} = {
        website = iguanaLib.mkZigPackage {
          pname = "website";
          version = "0.1.0";
          src = ./.;
          # target = "x86_64-linux-gnu";
          releaseMode = "ReleaseFast";
          doCheck = false;
        };
      };
      devShells.${system}.default = iguanaLib.mkShell { withZls = true; };
    };
}

