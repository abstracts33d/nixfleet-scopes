# Rename shims for base — one-release deprecation window for upstream consumers.
{lib, ...}: {
  imports = [
    (lib.mkRenamedOptionModule
      ["nixfleet" "terminalCompat" "enable"]
      ["nixfleet" "base" "terminfo" "enable"])
  ];
}
