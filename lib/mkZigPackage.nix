{ nixpkgs, inputs, zigSystem, zigPkgs, zigStable }:
system:
{ pname, version, src, target ? zigSystem, releaseMode ? "ReleaseSafe"
, zigBuildFlags ? [ ], zigVersion ? zigStable, nativeBuildInputs ? [ ] }@args:
let
  mkZigOverlay = import ./mkZigOverlay.nix { inherit zigPkgs zigVersion; };
  lib = nixpkgs.lib;

  pkgs = import nixpkgs {
    inherit system;
    overlays = [ (mkZigOverlay zigVersion) ];
  };

  fromZon = import ./fromZon.nix { inherit lib pkgs; };

  fetchDepsRecursive = src:
    let
      zonPath = builtins.trace "Zon Path: ${src + "/build.zig.zon"}"
        (src + "/build.zig.zon");
      hasZon = builtins.pathExists zonPath;
      zonText = if hasZon then builtins.readFile zonPath else "";
      zon = if hasZon then fromZon zonText else { dependencies = [ ]; };

      fetchDep = dep:
        let
          depUrl = builtins.trace "Dep Url: ${dep.url}" dep.url;
          gitUrlParts = let
            withRef = builtins.match "git\\+(.+)\\?ref=(.+)#(.+)" depUrl;
            withoutRef = builtins.match "git\\+(.+)#(.+)" dep.url;
          in if withRef != null then withRef else withoutRef;
          isGit = lib.hasPrefix "git+" dep.url;

          depSrc = if isGit then
            let
              repoUrl = builtins.head gitUrlParts;
              ref = if builtins.length gitUrlParts == 3 then
                builtins.elemAt gitUrlParts 1
              else
                null;
              # Hash is last element in both formats
              rev =
                builtins.elemAt gitUrlParts (builtins.length gitUrlParts - 1);
            in builtins.fetchGit {
              url = repoUrl;
              rev = rev;
              ref = if ref != null then ref else "HEAD";
            }
          else
            throw "Only Git URLs are supported right now";

          # Recursively fetch subdependencies
          subDeps = fetchDepsRecursive depSrc;
        in {
          inherit (dep) hash url;
          src = depSrc;
          dependencies = subDeps;
        };
    in map fetchDep zon.dependencies;

  allDeps = fetchDepsRecursive src;

  flattenDeps = deps:
    let
      collect = dep:
        [ (removeAttrs dep [ "dependencies" ]) ]
        ++ lib.concatMap collect dep.dependencies;
      allDeps = lib.concatMap collect deps;
    in lib.unique (lib.filter (dep: dep != null) allDeps);

  flatDeps = flattenDeps allDeps;

  zigDeps = pkgs.stdenv.mkDerivation (args // {
    name = "${pname}-deps";
    inherit src version;

    nativeBuildInputs = (args.nativeBuildInputs or [ ]) ++ [ pkgs.zig pkgs.jq ];

    buildPhase = ''
      mkdir -p $TMPDIR/zig-global-cache/p/
      mkdir -p $TMPDIR/zig-cache/

      # Save dependency information
      mkdir -p $TMPDIR/dep-info
      cat > $TMPDIR/dep-info/deps-tree.json << EOF
      $(echo '${builtins.toJSON allDeps}' | jq '.')
      EOF
      cat > $TMPDIR/dep-info/deps-flat.json << EOF
      $(echo '${builtins.toJSON flatDeps}' | jq '.')
      EOF

      # Copy all dependencies to cache
      ${lib.concatStringsSep "\n" (lib.imap0 (i: dep: ''
        cp -r ${dep.src} $TMPDIR/zig-global-cache/p/${dep.hash}
      '') flatDeps)}

      if [ -f build.zig.zon ]; then
        zig build --fetch --cache-dir $TMPDIR/zig-cache --global-cache-dir $TMPDIR/zig-global-cache
      fi
    '';

    installPhase = ''
      mkdir -p $out
      mkdir -p $out/zig-cache
      mkdir -p $out/zig-global-cache
      cp -r $TMPDIR/zig-global-cache $out
      cp -r $TMPDIR/zig-cache $out
      cp -r $TMPDIR/dep-info $out
    '';

    dontFixup = true;
  });

in pkgs.stdenv.mkDerivation (args // {
  inherit pname version src;
  nativeBuildInputs = (args.nativeBuildInputs or [ ]) ++ [ pkgs.zig ];

  preBuildPhases = [ "zigSetupPhase" ];
  zigSetupPhase = ''
    mkdir -p $TMPDIR/zig-global-cache
    mkdir -p $TMPDIR/zig-cache
    mkdir -p $out/dep-info
    cp -r ${zigDeps}/zig-global-cache $TMPDIR
    cp -r ${zigDeps}/zig-cache $TMPDIR || true

    cp -r ${zigDeps}/dep-info $out
  '';

  buildPhase = args.buildPhase or ''
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
  checkPhase = args.checkPhase or ''
    runHook preCheck

    zig build test --cache-dir $TMPDIR/zig-cache --global-cache-dir $TMPDIR/zig-global-cache

    runHook postCheck
  '';

  # Enable parallel building
  enableParallelBuilding = true;
})
