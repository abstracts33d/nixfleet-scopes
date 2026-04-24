# Base NixOS packages - truly universal tools for every NixOS host.
# Dev / graphical / media packages belong in their own fleet-side scopes.
# Tool configs are managed by Home Manager (via the HM variant at ./hm.nix).
{
  pkgs,
  lib,
  config,
  ...
}: {
  imports = [
    ./options.nix
    ./compat.nix
  ];

  config = lib.mkMerge [
    (lib.mkIf config.nixfleet.base.enable {
      environment.systemPackages = with pkgs; [
        unixtools.ifconfig
        unixtools.netstat
        xdg-utils
        curl
        wget
        unzip
      ];
    })
    (lib.mkIf (config.nixfleet.base.enable && config.nixfleet.base.terminfo.enable) {
      environment.systemPackages = with pkgs; [
        kitty.terminfo
        alacritty.terminfo
      ];
    })
  ];
}
