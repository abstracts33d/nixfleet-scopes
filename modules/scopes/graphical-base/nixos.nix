# Graphical-base — core NixOS plumbing for any graphical host.
# Portals, input, graphics, keyring, security. No DE-specific bits.
{
  config,
  pkgs,
  lib,
  ...
}: {
  config = lib.mkIf config.nixfleet.graphical.enable {
    environment.pathsToLink = ["/share/zsh" "/share/bash-completion"];

    security = {
      rtkit.enable = true;
      pam.services.login.enableGnomeKeyring = true;
      polkit.enable = true;
    };

    programs = {
      seahorse.enable = true;
      ssh.askPassword = lib.mkForce "${pkgs.seahorse}/libexec/seahorse/ssh-askpass";
      dconf.enable = true;
    };

    xdg.portal = {
      enable = true;
      extraPortals = [pkgs.xdg-desktop-portal-gtk];
      config.common.default = lib.mkDefault ["gtk"];
    };

    services = {
      libinput.enable = true;
      gvfs.enable = true;
      tumbler.enable = true;
      devmon.enable = true;
      udisks2.enable = true;
      upower.enable = true;
      power-profiles-daemon.enable = true;
      gnome.gnome-keyring.enable = true;
    };

    # Allow wheel users to mount/unmount drives without password.
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if ((action.id == "org.freedesktop.udisks2.filesystem-mount-system" ||
             action.id == "org.freedesktop.udisks2.filesystem-mount" ||
             action.id == "org.freedesktop.udisks2.filesystem-unmount-others" ||
             action.id == "org.freedesktop.udisks2.encrypted-unlock") &&
            subject.isInGroup("wheel")) {
          return polkit.Result.YES;
        }
      });
    '';

    environment.sessionVariables = {
      _JAVA_AWT_WM_NONREPARENTING = "1";
    };

    hardware.graphics.enable = true;
  };
}
