# Samba/SMB client — option declarations (cross-platform).
{lib, ...}: let
  types = lib.types;
in {
  options.nixfleet.sambaClient = {
    enable = lib.mkEnableOption "SMB client auto-mounts";

    mounts = lib.mkOption {
      type = types.listOf (types.submodule {
        options = {
          share = lib.mkOption {
            type = types.str;
            description = "Name of the share on the server.";
          };
          mountpoint = lib.mkOption {
            type = types.str;
            description = "Local mountpoint (absolute path).";
          };
          server = lib.mkOption {
            type = types.str;
            description = "Server IP or resolvable hostname.";
          };
          credentialsFile = lib.mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "CIFS credentials file. Null = guest access.";
          };
          readOnly = lib.mkOption {
            type = types.bool;
            default = false;
            description = "Mount read-only.";
          };
          uid = lib.mkOption {
            type = types.nullOr types.int;
            default = null;
            description = "Owner UID for the mount (Linux). Null = default.";
          };
          gid = lib.mkOption {
            type = types.int;
            default = 100;
            description = "Owner GID for the mount (Linux).";
          };
        };
      });
      default = [];
      description = "SMB shares to auto-mount.";
    };

    idleTimeoutSeconds = lib.mkOption {
      type = types.int;
      default = 60;
      description = "Idle timeout before auto-unmounting (Linux systemd-automount).";
    };
  };
}
