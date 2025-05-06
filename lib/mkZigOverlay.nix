{
  zigPkgs,
}:
zigVersion: final: prev: {
  zig = zigPkgs.packages.${prev.system}.${zigVersion};
}
