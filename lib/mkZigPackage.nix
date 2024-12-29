{
  nixpkgs,
  inputs,
  zigSystem,
  zigPkgs,
  zigStable,
}: system: {
  pname,
  version,
  src,
  depsHash ? "",
  target ? zigSystem,
  releaseMode ? "ReleaseSafe",
  zigBuildFlags ? [],
  zigVersion ? zigStable,
  nativeBuildInputs ? [],
  ...
} @ args: let
  mkZigOverlay = import ./mkZigOverlay.nix {inherit zigPkgs zigVersion;};
  lib = nixpkgs.lib;

  pkgs = import nixpkgs {
    inherit system;
    overlays = [(mkZigOverlay zigVersion)];
  };

  fetchScript =
    pkgs.writeText "zig-fetch.py" "${(builtins.readFile ./zig-fetch.py)}";

  zigDeps = pkgs.stdenv.mkDerivation (args
    // {
      name = "${pname}-deps";
      inherit src version;

      nativeBuildInputs = (args.nativeBuildInputs or []) ++ [pkgs.zig pkgs.python3 pkgs.jq];

      buildPhase = ''
        mkdir -p $TMPDIR/zig-global-cache
        python3 ${fetchScript} ./build.zig.zon $TMPDIR/zig-global-cache
        ls $TMPDIR/zig-global-cache
      '';

      installPhase = ''
        mkdir -p $out/zig-global-cache
        mkdir -p $out/dep-info
        cp -r $TMPDIR/zig-global-cache $out
        cp ./build.zig.zon $out/dep-info/
      '';

      dontFixup = true;

      outputHashMode = "recursive";
      outputHashAlgo = "sha256";
      outputHash = depsHash;
    });
in
  pkgs.stdenv.mkDerivation (args
    // {
      inherit pname version src;
      nativeBuildInputs =
        (args.nativeBuildInputs or [])
        ++ [pkgs.autoPatchelfHook pkgs.zig];

      preBuildPhases = ["zigSetupPhase"];
      zigSetupPhase = ''
        mkdir -p $TMPDIR/zig-global-cache
        mkdir -p $TMPDIR/zig-cache
        mkdir -p $out/dep-info
        cp -r ${zigDeps}/zig-global-cache $TMPDIR
        chmod -R u+rw $TMPDIR/zig-global-cache
        cp -r ${zigDeps}/dep-info $out
      '';

      buildPhase =
        args.buildPhase
        or ''
          runHook preBuild

          zig build \
          --cache-dir $TMPDIR/zig-cache \
          --global-cache-dir $TMPDIR/zig-global-cache \
          -Dtarget=${target} \
          -Doptimize=${releaseMode} \
          -p $out ${lib.concatStringsSep " " zigBuildFlags}

          runHook postBuild
        '';

      doCheck = args.doCheck or true;
      checkPhase =
        args.checkPhase
        or ''
          runHook preCheck

          zig build test --cache-dir $TMPDIR/zig-cache --global-cache-dir $TMPDIR/zig-global-cache

          runHook postCheck
        '';

      # Enable parallel building
      enableParallelBuilding = true;
    })
