# Graphical-base scope — option declarations.
#
# variant is the SOURCE; enable + protocol are DERIVED defaults that
# the consumer can override. Consumers can also set enable=true from
# fleet-specific triggers (e.g. kids profile, GPU detection) without
# choosing a variant.
{
  config,
  lib,
  ...
}: {
  options.nixfleet.graphical = {
    variant = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum ["hyprland" "gnome" "budgie" "cinnamon"]);
      default = null;
      description = "Desktop environment variant. Null = no DE (headless/server). Mutex by construction.";
    };

    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether this host has a graphical session (any DE active).";
    };

    protocol = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum ["wayland" "x11"]);
      default = null;
      description = "Display protocol (derived from variant when null).";
    };

    fonts.extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Extra fonts to install on top of the baseline set.";
    };
  };

  config = {
    nixfleet.graphical.enable = lib.mkDefault (config.nixfleet.graphical.variant != null);

    nixfleet.graphical.protocol = lib.mkDefault (
      if config.nixfleet.graphical.variant == "cinnamon"
      then "x11"
      else if config.nixfleet.graphical.variant != null
      then "wayland"
      else null
    );
  };
}
