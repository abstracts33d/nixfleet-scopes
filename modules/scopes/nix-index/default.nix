# NixOS opinions for nix-index-database: pre-built weekly database + comma
# (`, <pkg>`) + command-not-found replacement.
#
# Consumer must also import inputs.nix-index-database.nixosModules.nix-index
# to get the underlying programs.nix-index options surface.
{
  config,
  lib,
  ...
}: {
  options.nixfleet.nix-index.enable =
    lib.mkEnableOption "nix-index-database opinions (comma + command-not-found replacement)";

  config = lib.mkIf config.nixfleet.nix-index.enable {
    programs.nix-index.enable = true;
    programs.nix-index-database.comma.enable = true;
    programs.command-not-found.enable = false;
  };
}
