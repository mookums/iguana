{ lib, pkgs }:
let
  removeComments = str:
    let
      lines = lib.splitString "\n" str;
      cleanedLines =
        builtins.filter (line: !(lib.hasPrefix "//" (lib.trim line))) lines;
    in lib.concatStringsSep "\n" cleanedLines;

  parseScript =
    pkgs.writeText "parse-zon.py" "${(builtins.readFile ./parse-zon.py)}";

  parseDependencies = zonStr:
    let
      zonFile = pkgs.writeText "build.zon" zonStr;
      deps = builtins.fromJSON (builtins.readFile
        (pkgs.runCommand "parse-deps" {
          buildInputs = with pkgs; [ python3 ];
        } ''
          python3 ${parseScript} ${zonFile} > $out
        ''));
    in deps;

in zonStr:
let
  cleaned = removeComments zonStr;
  nameMatch = builtins.match ''.*\.name = "([^"]*)".*'' cleaned;
  versionMatch = builtins.match ''.*\.version = "([^"]*)".*'' cleaned;
  dependencies = parseDependencies cleaned;

  result = {
    dependencies = if builtins.isList dependencies then dependencies else [ ];
    name = if nameMatch != null then builtins.head nameMatch else null;
    version = if versionMatch != null then builtins.head versionMatch else null;
  };

  # tracedResult = builtins.trace "Result: ${builtins.toJSON result}" result;
in result
