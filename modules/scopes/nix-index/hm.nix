# Home Manager opinion for nix-index-database.
#
# Consumer must also import inputs.nix-index-database.homeModules.nix-index.
{
  config,
  lib,
  ...
}: {
  options.nixfleet.nix-index.enable =
    lib.mkEnableOption "nix-index HM opinion";

  config = lib.mkIf config.nixfleet.nix-index.enable {
    programs.nix-index.enable = true;
  };
}
