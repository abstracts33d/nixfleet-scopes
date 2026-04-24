# Tailscale scope — nix-darwin (minimal). Consumer handles CA trust,
# /etc/hosts seeding, and any keychain integration separately — those
# are org-specific decisions.
{
  config,
  lib,
  ...
}: let
  cfg = config.nixfleet.tailscale;
in {
  imports = [./options.nix];

  config = lib.mkIf cfg.enable {
    services.tailscale.enable = true;
  };
}
