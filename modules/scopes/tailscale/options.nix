# Tailscale scope — option declarations (cross-platform).
{lib, ...}: {
  options.nixfleet.tailscale = {
    enable = lib.mkEnableOption "Tailscale mesh VPN client";

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open Tailscale's direct-connection ports in the firewall (NixOS).";
    };

    persistState = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Persist /var/lib/tailscale on impermanent hosts (NixOS).";
    };

    autoAuth = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Auto-join the tailnet on first boot using an OAuth secret.";
      };

      secretFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Path to the file containing the Tailscale OAuth secret (one line). Required when autoAuth.enable is true.";
      };

      advertiseTags = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        example = ["tag:fleet"];
        description = "Tags to advertise on first-boot `tailscale up`.";
      };
    };
  };
}
