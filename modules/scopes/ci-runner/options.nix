# CI runner scope — option declarations.
# Two drivers: Hercules CI agent (Nix-native) and Forgejo Actions
# self-hosted runner (GitHub-Actions-compatible). Enable either or both.
{lib, ...}: let
  types = lib.types;
in {
  options.nixfleet.ciRunner = {
    hercules = {
      enable = lib.mkEnableOption "Hercules CI agent (Nix-native)";

      agentTokenFile = lib.mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "/run/secrets/hercules-agent-token";
        description = "Path to the Hercules agent token file. Required when hercules.enable is true.";
      };

      nixBinaryCaches = lib.mkOption {
        type = types.str;
        default = "";
        example = ''{"substituters":["https://cache.example.com"],"trusted-public-keys":["..."]}'';
        description = "Optional JSON string describing extra substituters the agent trusts.";
      };

      concurrentTasks = lib.mkOption {
        type = types.int;
        default = 4;
        description = "Maximum concurrent Nix builds.";
      };
    };

    forgejoActions = {
      enable = lib.mkEnableOption "Forgejo Actions self-hosted runner";

      instanceUrl = lib.mkOption {
        type = types.str;
        default = "http://localhost:3001";
        description = "URL of the Forgejo instance the runner registers with.";
      };

      registrationTokenFile = lib.mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "/run/secrets/forgejo-runner-token";
        description = "Path to the runner registration token file. Required when forgejoActions.enable is true.";
      };

      name = lib.mkOption {
        type = types.str;
        default = "nixfleet-runner";
        description = "Runner display name.";
      };

      labels = lib.mkOption {
        type = types.listOf types.str;
        default = ["nixos:host" "native:host"];
        description = "Labels the runner advertises. native:host lets workflows target direct-host execution.";
      };

      capacity = lib.mkOption {
        type = types.int;
        default = 2;
        description = "Parallel jobs the runner accepts.";
      };

      enableContainers = lib.mkOption {
        type = types.bool;
        default = false;
        description = "Allow container-based jobs (needs docker/podman).";
      };
    };
  };
}
