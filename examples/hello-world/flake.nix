{
  description = "";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-24.11";
    iguana.url = "github:mookums/iguana";
  };

  outputs = {iguana, ...}: let
    system = "x86_64-linux";
    iguanaLib = iguana.lib.${system};
  in {
    packages.${system} = {
      hello-world = iguanaLib.mkZigPackage {
        pname = "hello-world";
        version = "0.1.0";
        src = ./.;
        depsHash = "sha256-bzzRYxC64g3LmnJ2nfmFjuD8rqjYatwWjXY8XgAk8T0=";
        # target = "x86_64-linux-gnu";
        releaseMode = "Debug";
        doCheck = false;
      };
    };
    devShells.${system}.default = iguanaLib.mkShell {withZls = true;};
  };
}
