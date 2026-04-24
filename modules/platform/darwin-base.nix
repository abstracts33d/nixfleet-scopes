# Darwin platform shim - minimal common config readable from hostSpec
# identity. Optional: mkHost already handles most of this. This shim
# exists so roles/hosts that bypass mkHost can still pick up sensible
# defaults with a single import.
#
# Also exposes nixfleet.darwin.homebrew.* scaffolding when the consumer
# imports inputs.nix-homebrew.darwinModules.nix-homebrew alongside this
# shim. Taps/brews/casks/masApps lists are empty by default — fleet
# fills them.
{
  config,
  lib,
  ...
}: let
  hS = config.hostSpec;
  hb = config.nixfleet.darwin.homebrew;
in {
  options.nixfleet.darwin.homebrew = {
    enable = lib.mkEnableOption "nix-homebrew + homebrew wiring (Darwin). Consumer must also import inputs.nix-homebrew.darwinModules.nix-homebrew.";

    user = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "User to run brew as. Null = nixfleet.operators._primaryName.";
    };

    taps = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = {};
      description = "Taps to wire into nix-homebrew. Values are flake-input paths to the tap sources.";
    };

    brews = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Homebrew formulae to install.";
    };

    casks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Homebrew casks to install.";
    };

    masApps = lib.mkOption {
      type = lib.types.attrsOf lib.types.int;
      default = {};
      description = "Mac App Store apps: {name = appleId;}.";
    };

    onActivation = {
      autoUpdate = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Run brew update on activation.";
      };
      cleanup = lib.mkOption {
        type = lib.types.enum ["none" "uninstall" "zap"];
        default = "zap";
        description = "Cleanup policy for brews not in the declared list.";
      };
      upgrade = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Upgrade outdated brews on activation.";
      };
    };
  };

  config = lib.mkMerge [
    {
      time.timeZone = lib.mkDefault hS.timeZone;
      nix.settings.experimental-features = lib.mkDefault ["nix-command" "flakes"];
    }

    (lib.mkIf hb.enable {
      nix-homebrew = {
        enable = true;
        user =
          if hb.user != null
          then hb.user
          else config.nixfleet.operators._primaryName;
        inherit (hb) taps;
        mutableTaps = false;
        autoMigrate = true;
      };

      homebrew = {
        enable = true;
        taps = builtins.attrNames hb.taps;
        inherit (hb) brews casks masApps onActivation;
      };
    })
  ];
}
