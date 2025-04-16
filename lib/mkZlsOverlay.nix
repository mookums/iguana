{
  zigPkgs,
  zigVersion,
}: zigVersion: final: prev: {
 zls = zigPkgs.packages.${prev.system}.${zigVersion}.zls;
}
