# Samba/SMB client — NixOS systemd-automount.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.nixfleet.sambaClient;

  mkMount = m: let
    baseOpts =
      [
        "x-systemd.automount"
        "noauto"
        "x-systemd.idle-timeout=${toString cfg.idleTimeoutSeconds}"
        "x-systemd.device-timeout=5s"
        "x-systemd.mount-timeout=5s"
        "file_mode=0664"
        "dir_mode=0775"
      ]
      ++ lib.optional (m.credentialsFile == null) "guest"
      ++ lib.optional (m.credentialsFile != null) "credentials=${m.credentialsFile}"
      ++ lib.optional (m.uid != null) "uid=${toString m.uid}"
      ++ ["gid=${toString m.gid}"]
      ++ lib.optional m.readOnly "ro";
  in {
    name = m.mountpoint;
    value = {
      device = "//${m.server}/${m.share}";
      fsType = "cifs";
      options = baseOpts;
    };
  };
in {
  imports = [./options.nix];

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [pkgs.cifs-utils];
    fileSystems = lib.listToAttrs (map mkMount cfg.mounts);
  };
}
