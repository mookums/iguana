{ zigPkgs, zigVersion }:
zigVersion: final: prev: {
  zig = zigPkgs.packages.${prev.system}.${zigVersion};
}
