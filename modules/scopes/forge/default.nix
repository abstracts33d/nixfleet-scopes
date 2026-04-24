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

    # Optional bootstrap admin creation on first start, plus declarative
    # SSH-key registration on every start (idempotent — Forgejo dedupes
    # by fingerprint).
    systemd.services.forgejo = lib.mkIf (cfg.admin.userFile != null) {
      preStart = lib.mkAfter ''
        admin_user=""
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

        ${lib.optionalString (cfg.admin.sshKeyFiles != []) ''
          # Register declared SSH keys on the admin account. Re-read the
          # admin username from userFile in case the admin was created on
          # a previous run (marker already existed).
          if [ -z "$admin_user" ] && [ -r ${cfg.admin.userFile} ]; then
            IFS=: read -r admin_user _ _ < ${cfg.admin.userFile}
          fi
          if [ -n "$admin_user" ]; then
            ${lib.concatMapStringsSep "\n" (keyFile: ''
              if [ -r ${keyFile} ]; then
                key_content="$(cat ${keyFile})"
                if [ -n "$key_content" ]; then
                  echo "forge: registering SSH key ${keyFile} for $admin_user" >&2
                  # add-ssh-key is idempotent on the Forgejo side (fingerprint
                  # dedupe). Errors are non-fatal to avoid blocking service start.
                  ${pkgs.forgejo}/bin/forgejo admin user add-ssh-key \
                    --username "$admin_user" \
                    --key "$key_content" \
                    || echo "forge: add-ssh-key failed for ${keyFile} (continuing)" >&2
                fi
              else
                echo "forge: SSH key file ${keyFile} not readable, skipping" >&2
              fi
            '')
            cfg.admin.sshKeyFiles}
          else
            echo "forge: admin user unknown, skipping sshKeyFiles registration" >&2
          fi
        ''}
      '';
    };

    # Declarative repository pre-creation. Runs after forgejo.service is
    # active, gated on the admin-created marker (bounded wait to avoid
    # hanging on a genuinely broken bootstrap).
    #
    # TODO(v2): extend the submodule + this unit with pullMirror support
    # (upstream URL + auth) so declared repos can be pull-mirrors of
    # external sources. Out of scope for v1.
    systemd.services.forgejo-repositories = lib.mkIf (cfg.repositories != []) {
      description = "Declarative Forgejo repository pre-creation";
      after = ["forgejo.service"];
      wants = ["forgejo.service"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "forgejo";
        Group = "forgejo";
      };

      script = ''
        set -u

        # Gate: wait (bounded) for the admin-created marker. The marker is
        # written by forgejo.service preStart after `admin user create`.
        waited=0
        while [ ! -f ${cfg.dataDir}/.nixfleet-admin-created ]; do
          if [ $waited -ge 60 ]; then
            echo "forge-repositories: admin marker missing after 60s, aborting" >&2
            exit 0
          fi
          sleep 1
          waited=$((waited + 1))
        done

        ${lib.concatMapStringsSep "\n" (repo: let
            privateFlag =
              if repo.private
              then "--private"
              else "";
          in ''
            if [ -d ${cfg.dataDir}/repositories/${repo.owner}/${repo.name}.git ]; then
              echo "forge-repositories: ${repo.owner}/${repo.name} already exists, skipping" >&2
            else
              echo "forge-repositories: creating ${repo.owner}/${repo.name}" >&2
              ${pkgs.forgejo}/bin/forgejo admin repo create \
                --owner ${lib.escapeShellArg repo.owner} \
                --name ${lib.escapeShellArg repo.name} \
                --description ${lib.escapeShellArg repo.description} \
                --default-branch ${lib.escapeShellArg repo.defaultBranch} \
                ${privateFlag} \
                || echo "forge-repositories: create failed for ${repo.owner}/${repo.name} (continuing)" >&2
            fi
          '')
          cfg.repositories}
      '';
    };

    # Forgejo's integrated SSH server binds cfg.ssh.port as the
    # unprivileged `forgejo` user. Ports <1024 are privileged by default.
    # The NixOS forgejo module sets NoNewPrivileges=true, which prevents
    # AmbientCapabilities=CAP_NET_BIND_SERVICE from taking effect at exec
    # time. Lower the unprivileged-port-start sysctl instead so any
    # user-space process can bind cfg.ssh.port without needing caps.
    boot.kernel.sysctl = lib.mkIf (cfg.ssh.enable && cfg.ssh.port < 1024) {
      "net.ipv4.ip_unprivileged_port_start" = cfg.ssh.port;
    };

    environment.persistence."/persist".directories = lib.mkIf (config.nixfleet.impermanence.enable or false) [
      {
        directory = cfg.dataDir;
        user = "forgejo";
        group = "forgejo";
        mode = "0750";
      }
    ];

    # forgejo-secrets.service's systemd sandbox bind-mounts stateDir/custom
    # read-write into its namespace. On a fresh stateDir (first boot on an
    # impermanent host, or a bare install), the subdirectory doesn't exist
    # yet and the namespace setup fails with status=226/NAMESPACE. Pre-create
    # it via tmpfiles so the sandbox has something to bind.
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir}/custom 0750 forgejo forgejo - -"
    ];
  };
}
