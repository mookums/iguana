{lib}: system: let
  parseNixSystem = system: let
    parts = builtins.match "([^-]+)-([^-]+)(-([^-]+))?" system;
  in
    if parts == null
    then throw "Invalid Nix system format: ${system}"
    else {
      cpu = builtins.elemAt parts 0;
      os = builtins.elemAt parts 1;
      vendor = builtins.elemAt parts 2;
    };

  translateCpu = nixCpu:
    {
      "x86_64" = "x86_64";
      "i686" = "x86";
      "aarch64" = "aarch64";
      "armv7l" = "arm";
      "armv6l" = "arm";
      "riscv64" = "riscv64";
      "powerpc64le" = "powerpc64le";
    }
    .${nixCpu}
    or (throw "Unsupported CPU architecture: ${nixCpu}");

  translateOs = nixOs:
    {
      "linux" = "linux";
      "darwin" = "macos";
      "windows" = "windows";
      "freebsd" = "freebsd";
      "openbsd" = "openbsd";
      "netbsd" = "netbsd";
    }
    .${nixOs}
    or (throw "Unsupported operating system: ${nixOs}");

  translateAbi = nixVendor: nixOs:
    if nixOs == "linux"
    then
      if nixVendor == "gnu"
      then "gnu"
      else if nixVendor == "musl"
      then "musl"
      else "gnu"
    else "";
in let
  parsed = parseNixSystem system;
  cpu = translateCpu parsed.cpu;
  os = translateOs parsed.os;
  abi = translateAbi parsed.vendor parsed.os;
  target =
    if abi != ""
    then "${cpu}-${os}-${abi}"
    else "${cpu}-${os}";
in
  target
