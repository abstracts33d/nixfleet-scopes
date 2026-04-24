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

      environment.persistence."/persist".directories =
        lib.mkIf (config.nixfleet.impermanence.enable or false)
        ["/var/lib/gitea-runner-nixfleet"];
    })
  ];
}
