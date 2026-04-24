# CI runner scope — Hercules CI agent and/or Forgejo Actions runner.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.nixfleet.ciRunner;
in {
  imports = [./options.nix];

  config = lib.mkMerge [
    (lib.mkIf cfg.hercules.enable {
      assertions = [
        {
          assertion = cfg.hercules.agentTokenFile != null;
          message = "nixfleet.ciRunner.hercules.enable requires hercules.agentTokenFile.";
        }
      ];

      services.hercules-ci-agent = {
        enable = true;
        settings = {
          concurrentTasks = cfg.hercules.concurrentTasks;
        };
      };

      systemd.services.hercules-ci-agent.serviceConfig = {
        LoadCredential = "agent-token:${cfg.hercules.agentTokenFile}";
        Environment = ["HERCULES_CI_AGENT_TOKEN_FILE=%d/agent-token"];
      };
    })

    (lib.mkIf cfg.forgejoActions.enable {
      assertions = [
        {
          assertion = cfg.forgejoActions.registrationTokenFile != null;
          message = "nixfleet.ciRunner.forgejoActions.enable requires forgejoActions.registrationTokenFile.";
        }
      ];

      services.gitea-actions-runner = {
        package = pkgs.forgejo-runner;
        instances.nixfleet = {
          enable = true;
          inherit (cfg.forgejoActions) name;
          url = cfg.forgejoActions.instanceUrl;
          tokenFile = cfg.forgejoActions.registrationTokenFile;
          labels = cfg.forgejoActions.labels;
          settings = {
            runner.capacity = cfg.forgejoActions.capacity;
            container.enable = cfg.forgejoActions.enableContainers;
            log.level = "info";
          };
        };
      };

      # Runner environment — two things:
      #
      # 1. Give the runner (and its subprocess shells) access to Nix and
      #    the standard toolchain every `runs-on: native` workflow
      #    expects. Without this, jobs fail with "command not found".
      #
      #    Uses NixOS's `.path` attribute — additive, merges the listed
      #    packages into PATH without touching the rest of the env.
      #    (The earlier `serviceConfig.Environment = [ "PATH=..." ]`
      #    approach REPLACED the entire env — stripped HOME,
      #    LOCALE_ARCHIVE, TZDIR etc. and broke the runner at activation.)
      #
      #    Consumers that need extras (attic-client, a TPM-sign wrapper,
      #    etc.) extend this list from their own host config:
      #
      #        systemd.services.gitea-runner-nixfleet.path = [ inputs.attic... ];
      #
      # 2. Order the runner after forgejo.service when the runner points
      #    at a local Forgejo instance. Avoids a race on rebuild where
      #    both services restart simultaneously, runner boots before
      #    forgejo accepts connections, and exits 1. systemd auto-retries
      #    and succeeds ~2s later, but the visible exit status on
      #    nixos-rebuild looks like a failure.
      systemd.services.gitea-runner-nixfleet =
        {
          path = with pkgs; [
            config.nix.package
            bash
            coreutils
            findutils
            gnugrep
            gnused
            gawk
            gnutar
            gzip
            git
            jq
            curl
            openssl
          ];
        }
        // lib.optionalAttrs (lib.hasPrefix "http://localhost" cfg.forgejoActions.instanceUrl
          || lib.hasPrefix "http://127.0.0.1" cfg.forgejoActions.instanceUrl) {
          after = ["forgejo.service"];
          wants = ["forgejo.service"];
        };

      environment.persistence."/persist".directories =
        lib.mkIf (config.nixfleet.impermanence.enable or false)
        ["/var/lib/gitea-runner-nixfleet"];
    })
  ];
}
