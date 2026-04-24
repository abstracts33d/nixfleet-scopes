# Forgejo git forge scope.
#
# HTTP listens on loopback by default — consumer wires the reverse
# proxy (Caddy, nginx, ...). SSH binds a separate port (222 default)
# so the host's OpenSSH keeps :22.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.nixfleet.forge;
in {
  imports = [./options.nix];

  config = lib.mkIf cfg.enable {
    services.forgejo = {
      enable = true;
      stateDir = cfg.dataDir;
      database.type = cfg.database.type;
      inherit (cfg) lfs;

      settings = {
        DEFAULT.APP_NAME = cfg.appName;

        server = {
          DOMAIN = cfg.domain;
          ROOT_URL = "https://${cfg.domain}/";
          HTTP_ADDR = cfg.http.addr;
          HTTP_PORT = cfg.http.port;
          SSH_DOMAIN = cfg.domain;
          SSH_PORT = cfg.ssh.port;
          SSH_LISTEN_HOST = cfg.ssh.listenHost;
          START_SSH_SERVER = cfg.ssh.enable;
          LANDING_PAGE = "login";
        };

        service.DISABLE_REGISTRATION = cfg.disableRegistration;
        session.COOKIE_SECURE = true;

        actions = lib.mkIf cfg.actions.enable {
          ENABLED = true;
          DEFAULT_ACTIONS_URL = cfg.actions.defaultActionsUrl;
        };

        mailer = lib.mkIf cfg.smtp.enable {
          ENABLED = true;
          SMTP_ADDR = cfg.smtp.host;
          FROM = cfg.smtp.from;
          USER = cfg.smtp.user;
          PASSWD = lib.mkIf (cfg.smtp.passwordFile != null) "$(cat ${cfg.smtp.passwordFile})";
        };

        repository.DEFAULT_BRANCH = "main";
      };
    };

    # Optional bootstrap admin creation on first start.
    systemd.services.forgejo = lib.mkIf (cfg.admin.userFile != null) {
      preStart = lib.mkAfter ''
        if [ ! -f ${cfg.dataDir}/.nixfleet-admin-created ]; then
          if [ -r ${cfg.admin.userFile} ]; then
            IFS=: read -r admin_user admin_email admin_pass < ${cfg.admin.userFile}
            ${pkgs.forgejo}/bin/forgejo admin user create \
              --admin \
              --username "$admin_user" \
              --email "$admin_email" \
              --password "$admin_pass" || true
            touch ${cfg.dataDir}/.nixfleet-admin-created
          fi
        fi
      '';
    };

    environment.persistence."/persist".directories = lib.mkIf (config.nixfleet.impermanence.enable or false) [
      {
        directory = cfg.dataDir;
        user = "forgejo";
        group = "forgejo";
        mode = "0750";
      }
    ];
  };
}
