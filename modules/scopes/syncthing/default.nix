# Syncthing scope — NixOS. Thin wrapper over upstream services.syncthing.
{
  config,
  lib,
  ...
}: let
  cfg = config.nixfleet.syncthing;

  mkDevice = _name: dev: {
    id = dev.id;
    addresses = dev.addresses;
  };

  mkFolder = name: folder:
    {
      id = name;
      label = name;
      inherit (folder) path type;
      devices = folder.devices;
    }
    // lib.optionalAttrs (folder.versioning != null) {inherit (folder) versioning;};
in {
  imports = [./options.nix];

  config = lib.mkIf cfg.enable {
    services.syncthing = {
      enable = true;
      inherit (cfg) user dataDir openDefaultPorts;
      configDir =
        if cfg.configDir != null
        then cfg.configDir
        else "${cfg.dataDir}/.config/syncthing";
      overrideDevices = true;
      overrideFolders = true;
      settings = {
        devices = lib.mapAttrs mkDevice cfg.devices;
        folders = lib.mapAttrs mkFolder cfg.folders;
        options.autoAcceptFolders = cfg.autoAcceptFolders;
      };
    };
  };
}
