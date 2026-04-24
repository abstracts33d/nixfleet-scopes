# Tailscale scope — NixOS.
{
  config,
  lib,
  ...
}: let
  cfg = config.nixfleet.tailscale;
in {
  imports = [./options.nix];

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      services.tailscale = {
        enable = true;
        openFirewall = cfg.openFirewall;
      };
    }
    (lib.mkIf (cfg.persistState && (config.nixfleet.impermanence.enable or false)) {
      environment.persistence."/persist".directories = ["/var/lib/tailscale"];
    })
    (lib.mkIf cfg.autoAuth.enable {
      assertions = [
        {
          assertion = cfg.autoAuth.secretFile != null;
          message = "nixfleet.tailscale.autoAuth.enable requires autoAuth.secretFile.";
        }
      ];
      systemd.services.tailscale-autoauth = {
        description = "Tailscale auto-authentication via OAuth";
        after = ["tailscaled.service"];
        wants = ["tailscaled.service"];
        wantedBy = ["multi-user.target"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        path = [config.services.tailscale.package];
        script = let
          tagArgs =
            lib.optionalString (cfg.autoAuth.advertiseTags != [])
            "--advertise-tags ${lib.escapeShellArg (lib.concatStringsSep "," cfg.autoAuth.advertiseTags)}";
        in ''
          secret="${cfg.autoAuth.secretFile}"
          for i in $(seq 1 30); do
            [ -f "$secret" ] && break
            echo "Waiting for secret ($i/30)..."
            sleep 1
          done
          if [ ! -f "$secret" ]; then
            echo "ERROR: $secret not found after 30s"
            exit 1
          fi
          if tailscale status >/dev/null 2>&1; then
            echo "Tailscale already authenticated, skipping"
            exit 0
          fi
          tailscale up --authkey "$(cat "$secret")" ${tagArgs}
        '';
      };
    })
  ]);
}
