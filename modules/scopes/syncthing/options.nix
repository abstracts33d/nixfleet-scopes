# Syncthing scope — option declarations (cross-platform).
{lib, ...}: let
  types = lib.types;
in {
  options.nixfleet.syncthing = {
    enable = lib.mkEnableOption "Syncthing P2P file sync";

    user = lib.mkOption {
      type = types.str;
      description = "User the Syncthing service runs as.";
    };

    dataDir = lib.mkOption {
      type = types.str;
      description = "User's data root (typically HOME).";
    };

    configDir = lib.mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Config directory for Syncthing. Defaults per platform when null.";
    };

    devices = lib.mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          id = lib.mkOption {
            type = types.str;
            description = "Device ID (RSA public-key fingerprint).";
          };
          addresses = lib.mkOption {
            type = types.listOf types.str;
            default = ["dynamic"];
            description = "Address hints for discovery.";
          };
        };
      });
      default = {};
      description = "Remote Syncthing devices (attrs keyed by name). Self should be excluded by the consumer via hostName filter.";
    };

    folders = lib.mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          path = lib.mkOption {
            type = types.str;
            description = "Absolute local path for the folder.";
          };
          devices = lib.mkOption {
            type = types.listOf types.str;
            description = "Device names (keys from `devices`) that share this folder.";
          };
          type = lib.mkOption {
            type = types.enum ["sendreceive" "sendonly" "receiveonly"];
            default = "sendreceive";
            description = "Folder mode.";
          };
          versioning = lib.mkOption {
            type = types.nullOr types.attrs;
            default = null;
            description = "Versioning config (Syncthing native shape). Null = none.";
          };
        };
      });
      default = {};
      description = "Shared folders (attrs keyed by id).";
    };

    autoAcceptFolders = lib.mkOption {
      type = types.bool;
      default = true;
      description = "Auto-accept folder offers from known devices.";
    };

    openDefaultPorts = lib.mkOption {
      type = types.bool;
      default = true;
      description = "Open Syncthing's default ports in the firewall (NixOS).";
    };
  };
}
