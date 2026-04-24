# Attic binary cache server scope — option declarations.
{lib, ...}: let
  types = lib.types;
in {
  options.nixfleet.atticServer = {
    enable = lib.mkEnableOption "Attic binary cache server";

    domain = lib.mkOption {
      type = types.str;
      example = "cache.lab.internal";
      description = "Public domain for the cache (used by downstream consumers for substituter URLs).";
    };

    listen = lib.mkOption {
      type = types.str;
      default = "127.0.0.1:8081";
      description = "Bind address:port. Use 127.0.0.1 when fronted by a reverse proxy.";
    };

    openFirewall = lib.mkOption {
      type = types.bool;
      default = false;
      description = "Open the listen port in the firewall. Disable when a reverse proxy fronts the service.";
    };

    dbPath = lib.mkOption {
      type = types.str;
      default = "/var/lib/nixfleet-attic/server.db";
      description = "SQLite database path.";
    };

    signing.privateKeyFile = lib.mkOption {
      type = types.str;
      example = "/run/secrets/attic-signing-key";
      description = "Path to the ed25519 private key the cache signs closures with.";
    };

    storage = {
      type = lib.mkOption {
        type = types.enum ["local" "s3"];
        default = "local";
      };
      local.path = lib.mkOption {
        type = types.str;
        default = "/var/lib/nixfleet-attic/storage";
      };
      s3 = {
        bucket = lib.mkOption {
          type = types.str;
          default = "";
        };
        region = lib.mkOption {
          type = types.str;
          default = "";
        };
        endpoint = lib.mkOption {
          type = types.nullOr types.str;
          default = null;
        };
      };
    };

    garbageCollection = {
      schedule = lib.mkOption {
        type = types.str;
        default = "weekly";
      };
      keepSinceLastPush = lib.mkOption {
        type = types.str;
        default = "90 days";
      };
    };
  };
}
