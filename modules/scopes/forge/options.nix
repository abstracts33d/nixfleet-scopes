# Forge scope — option declarations.
{lib, ...}: let
  types = lib.types;
in {
  options.nixfleet.forge = {
    enable = lib.mkEnableOption "Forgejo self-hosted git forge";

    domain = lib.mkOption {
      type = types.str;
      example = "git.lab.internal";
      description = "Public domain for the forge. Used for DOMAIN + ROOT_URL generation.";
    };

    appName = lib.mkOption {
      type = types.str;
      default = "Forgejo";
      description = "Display name shown in the forge UI.";
    };

    dataDir = lib.mkOption {
      type = types.str;
      default = "/var/lib/forgejo";
      description = "State directory for the forge.";
    };

    http = {
      addr = lib.mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "HTTP listen address. Defaults to loopback on the assumption a reverse proxy handles TLS.";
      };
      port = lib.mkOption {
        type = types.port;
        default = 3001;
        description = "HTTP listen port.";
      };
    };

    ssh = {
      enable = lib.mkOption {
        type = types.bool;
        default = true;
        description = "Run Forgejo's integrated SSH server for git push/clone.";
      };
      port = lib.mkOption {
        type = types.port;
        default = 222;
        description = "Forgejo SSH listen port. Keep separate from OpenSSH (22).";
      };
      listenHost = lib.mkOption {
        type = types.str;
        default = "0.0.0.0";
        description = "Forgejo SSH bind address.";
      };
    };

    actions = {
      enable = lib.mkOption {
        type = types.bool;
        default = true;
        description = "Enable Forgejo Actions (native CI).";
      };
      defaultActionsUrl = lib.mkOption {
        type = types.str;
        default = "github";
        description = "Where to fetch reusable actions from. \"github\" = fetch github.com/actions/*; \"self\" = require mirrors in Forgejo.";
      };
    };

    disableRegistration = lib.mkOption {
      type = types.bool;
      default = true;
      description = "Disable open user registration. Single-operator / invite-only posture.";
    };

    database.type = lib.mkOption {
      type = types.enum ["sqlite3" "postgres" "mysql"];
      default = "sqlite3";
      description = "Database backend.";
    };

    lfs.enable = lib.mkOption {
      type = types.bool;
      default = true;
      description = "Enable Git LFS support.";
    };

    smtp = {
      enable = lib.mkOption {
        type = types.bool;
        default = false;
        description = "Enable outbound SMTP for notifications.";
      };
      host = lib.mkOption {
        type = types.str;
        default = "";
        example = "smtp.example.com:587";
        description = "SMTP host (host:port).";
      };
      from = lib.mkOption {
        type = types.str;
        default = "";
        example = "forge@example.com";
        description = "MAIL FROM address.";
      };
      user = lib.mkOption {
        type = types.str;
        default = "";
        description = "SMTP auth user.";
      };
      passwordFile = lib.mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "File containing the SMTP auth password.";
      };
    };

    admin = {
      userFile = lib.mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Optional file containing the bootstrap admin credentials (\"USER:EMAIL:PASSWORD\" on one line). When set, Forgejo creates the admin on first start.";
      };
    };
  };
}
