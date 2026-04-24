# Syncthing scope — nix-darwin.
# Runs syncthing as a launchd user agent and configures devices/folders
# through the REST API on startup and hourly (Syncthing's Nix-native
# module doesn't target nix-darwin, so we drive it via the API).
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.nixfleet.syncthing;

  configDir =
    if cfg.configDir != null
    then cfg.configDir
    else "${cfg.dataDir}/Library/Application Support/Syncthing";

  deviceJson = name: dev:
    builtins.toJSON {
      deviceID = dev.id;
      name = name;
      addresses = dev.addresses;
      autoAcceptFolders = cfg.autoAcceptFolders;
    };

  deviceUpsertExpr = name: dev: let
    json = deviceJson name dev;
  in ''
    if ((.devices | map(.deviceID) | index(${builtins.toJSON dev.id})) == null)
    then .devices += [${json}]
    else .devices |= map(if .deviceID == ${builtins.toJSON dev.id} then ${json} else . end)
    end
  '';

  allDeviceUpserts = lib.concatStringsSep " | " (
    lib.mapAttrsToList deviceUpsertExpr cfg.devices
  );

  folderUpsertExpr = name: folder: let
    deviceRefs = lib.concatStringsSep "," (map (d: builtins.toJSON {deviceID = cfg.devices.${d}.id;}) folder.devices);
    folderAttrs =
      {
        id = name;
        label = name;
        inherit (folder) path type;
      }
      // lib.optionalAttrs (folder.versioning != null) {inherit (folder) versioning;};
    folderPartial = builtins.toJSON folderAttrs;
  in ''
    FOLDER=$(echo ${lib.escapeShellArg folderPartial} | $JQ '. + {devices: [${deviceRefs}]}')
    CFG=$(echo "$CFG" | $JQ \
      --argjson folder "$FOLDER" \
      'if ((.folders | map(.id) | index(${builtins.toJSON name})) == null)
       then .folders += [$folder]
       else .folders |= map(if .id == ${builtins.toJSON name} then $folder else . end)
       end')
  '';

  allFolderUpserts = lib.concatStringsSep "\n" (lib.mapAttrsToList folderUpsertExpr cfg.folders);

  configScript = pkgs.writeShellScript "nixfleet-syncthing-config" ''
    set -euo pipefail
    API="http://127.0.0.1:8384"
    CURL="${pkgs.curl}/bin/curl"
    JQ="${pkgs.jq}/bin/jq"
    CONFIG_DIR=${lib.escapeShellArg configDir}

    for i in $(seq 1 30); do
      $CURL -sf "$API/rest/noauth/health" >/dev/null 2>&1 && break
      sleep 1
    done
    $CURL -sf "$API/rest/noauth/health" >/dev/null || { echo "Syncthing API not ready after 30s"; exit 1; }

    API_KEY=$(grep -o '<apikey>[^<]*' "$CONFIG_DIR/config.xml" | cut -d'>' -f2)
    [ -n "$API_KEY" ] || { echo "could not read API key from $CONFIG_DIR/config.xml"; exit 1; }
    H="-H X-API-Key:$API_KEY"

    CFG=$($CURL -sf $H "$API/rest/config")
    ${lib.optionalString (cfg.devices != {}) ''CFG=$(echo "$CFG" | $JQ '${allDeviceUpserts}')''}
    ${allFolderUpserts}
    $CURL -sf $H -X PUT -H "Content-Type: application/json" -d "$CFG" "$API/rest/config"
  '';
in {
  imports = [./options.nix];

  config = lib.mkIf cfg.enable {
    launchd.user.agents.nixfleet-syncthing = {
      serviceConfig = {
        Label = "net.nixfleet.syncthing";
        ProgramArguments = [
          "${pkgs.syncthing}/bin/syncthing"
          "serve"
          "--no-browser"
          "--home=${configDir}"
        ];
        RunAtLoad = true;
        KeepAlive = true;
        ProcessType = "Background";
        StandardOutPath = "/tmp/nixfleet-syncthing.log";
        StandardErrorPath = "/tmp/nixfleet-syncthing.err";
      };
    };

    launchd.user.agents.nixfleet-syncthing-config = {
      serviceConfig = {
        Label = "net.nixfleet.syncthing-config";
        ProgramArguments = ["/bin/sh" "-c" "${configScript}"];
        RunAtLoad = true;
        StartInterval = 3600;
        StandardOutPath = "/tmp/nixfleet-syncthing-config.log";
        StandardErrorPath = "/tmp/nixfleet-syncthing-config.err";
      };
    };
  };
}
