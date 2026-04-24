# Samba/SMB client — macOS launchd agent that mounts at login + on
# network changes. Uses mount_smbfs with guest auth when credentialsFile
# is null; with a keychain entry (handled out-of-band) when a credentials
# file path is supplied.
{
  config,
  lib,
  ...
}: let
  cfg = config.nixfleet.sambaClient;

  mountCmd = m: let
    auth =
      if m.credentialsFile == null
      then "guest@"
      else ""; # Darwin looks up credentials in Keychain by host when no user@ is given.
    roFlag = lib.optionalString m.readOnly " -o ro";
  in ''
    if ! mount | grep -q "${m.mountpoint}"; then
      mkdir -p "${m.mountpoint}"
      mount_smbfs${roFlag} "//${auth}${m.server}/${m.share}" "${m.mountpoint}" 2>/dev/null || true
    fi
  '';

  mountScript = lib.concatStringsSep "\n" ([
      "#!/bin/sh"
    ]
    ++ (map mountCmd cfg.mounts));
in {
  imports = [./options.nix];

  config = lib.mkIf cfg.enable {
    launchd.user.agents.nixfleet-smb-mount = {
      serviceConfig = {
        Label = "net.nixfleet.smb-mount";
        ProgramArguments = ["/bin/sh" "-c" mountScript];
        RunAtLoad = true;
        WatchPaths = ["/Library/Preferences/SystemConfiguration"];
        StandardOutPath = "/tmp/nixfleet-smb-mount.log";
        StandardErrorPath = "/tmp/nixfleet-smb-mount.err";
      };
    };
  };
}
