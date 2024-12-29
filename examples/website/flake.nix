{
  description = "";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-24.11";
    #iguana.url = "github:mookums/iguana";
    iguana.url = "git+file://../../../";
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
          depsHash = "sha256-HHutq0c28myQCCNXlltSG4Si/vj7lRoXPiZ2DPf1g4s=";
          # target = "x86_64-linux-gnu";
          releaseMode = "ReleaseFast";
          doCheck = false;
        };
      };
      devShells.${system}.default = iguanaLib.mkShell { withZls = true; };
    };
}

