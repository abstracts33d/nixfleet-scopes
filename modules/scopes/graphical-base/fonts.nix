# Baseline system fonts for graphical hosts.
# Consumers add more via nixfleet.graphical.fonts.extraPackages or
# directly via fonts.packages.
{
  config,
  pkgs,
  lib,
  ...
}: {
  config = lib.mkIf config.nixfleet.graphical.enable {
    fonts.packages =
      (with pkgs; [
        nerd-fonts.meslo-lg
        dejavu_fonts
        jetbrains-mono
        font-awesome
        noto-fonts
        noto-fonts-color-emoji
      ])
      ++ config.nixfleet.graphical.fonts.extraPackages;
  };
}
