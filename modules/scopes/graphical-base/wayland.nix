# Wayland session environment variables.
# Only activates when protocol == "wayland"; X11 sessions must not set
# these (Electron/Chrome crash without a Wayland display).
{
  config,
  lib,
  ...
}: {
  config = lib.mkIf (config.nixfleet.graphical.protocol == "wayland") {
    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      QT_QPA_PLATFORM = "wayland";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    };
  };
}
