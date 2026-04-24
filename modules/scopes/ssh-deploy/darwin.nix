# Passwordless sudo for SSH-deploy activation on Darwin.
#
# The nixfleet CLI's SSH-deploy path runs as the primary operator
# (not root) and needs sudo for the profile update + activate steps only.
{
  config,
  lib,
  ...
}: let
  cfg = config.nixfleet.sshDeploy;
  primaryName = config.nixfleet.operators._primaryName;
in {
  options.nixfleet.sshDeploy.enable =
    lib.mkEnableOption "passwordless sudo for SSH-deploy activation (Darwin)";

  config = lib.mkIf cfg.enable {
    security.sudo.extraConfig = ''
      ${primaryName} ALL=(root) NOPASSWD: /nix/var/nix/profiles/default/bin/nix-env *
      ${primaryName} ALL=(root) NOPASSWD: /nix/store/*/bin/nix-env *
      ${primaryName} ALL=(root) NOPASSWD: /nix/store/*/activate
    '';
  };
}
