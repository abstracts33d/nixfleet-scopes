# Eval coverage for nixfleet-scopes.
#
# Evaluates each role with a minimal stub hostSpec and ensures the
# resulting NixOS configuration forces without throwing. Also spot-checks
# a couple of scope options so a typo in an option type is caught early.
{
  pkgs,
  lib,
  inputs,
  scopesPath,
}: let
  helpers = import ./_lib/helpers.nix {inherit lib;};

  mkSystem = extraModules:
    inputs.nixpkgs.lib.nixosSystem {
      system = pkgs.stdenv.hostPlatform.system;
      specialArgs = {inherit inputs;};
      modules =
        [
          helpers.hostSpecStub
          helpers.nixosEvalStub
          helpers.operatorsStub
        ]
        ++ extraModules;
    };

  # Standalone variant without operatorsStub - for scopes that don't
  # depend on the operators scope.
  mkStandaloneSystem = extraModules:
    inputs.nixpkgs.lib.nixosSystem {
      system = pkgs.stdenv.hostPlatform.system;
      specialArgs = {inherit inputs;};
      modules =
        [
          helpers.hostSpecStub
          helpers.nixosEvalStub
        ]
        ++ extraModules;
    };

  roles = {
    workstation = mkSystem [(scopesPath + "/modules/roles/workstation.nix")];
    server = mkSystem [(scopesPath + "/modules/roles/server.nix")];
    endpoint = mkSystem [(scopesPath + "/modules/roles/endpoint.nix")];
    microvm-guest = mkSystem [(scopesPath + "/modules/roles/microvm-guest.nix")];
  };

  standalone = {
    vpn = mkStandaloneSystem [
      (scopesPath + "/modules/scopes/vpn")
      {nixfleet.vpn.enable = false;}
    ];
    compliance = mkStandaloneSystem [
      (scopesPath + "/modules/scopes/compliance")
      (scopesPath + "/modules/scopes/impermanence")
      {nixfleet.compliance.enable = false;}
    ];
    remote-builders = mkStandaloneSystem [
      (scopesPath + "/modules/scopes/remote-builders")
      {nixfleet.distributedBuilds.enable = false;}
    ];
    monitoring-server = mkStandaloneSystem [
      (scopesPath + "/modules/scopes/monitoring-server")
      (scopesPath + "/modules/scopes/impermanence")
      {nixfleet.monitoring.server.enable = false;}
    ];

    # A.2 extracted scopes — default eval (inert) + sample enabled config.
    # Scopes that write environment.persistence paths need impermanence
    # imported alongside (the common deployment shape).
    tailscale-default = mkStandaloneSystem [
      (scopesPath + "/modules/scopes/tailscale")
      (scopesPath + "/modules/scopes/impermanence")
    ];
    tailscale-enabled = mkStandaloneSystem [
      (scopesPath + "/modules/scopes/tailscale")
      (scopesPath + "/modules/scopes/impermanence")
      {nixfleet.tailscale.enable = true;}
    ];
    samba-client-default = mkStandaloneSystem [
      (scopesPath + "/modules/scopes/samba-client")
      (scopesPath + "/modules/scopes/impermanence")
    ];
    samba-client-enabled = mkStandaloneSystem [
      (scopesPath + "/modules/scopes/samba-client")
      (scopesPath + "/modules/scopes/impermanence")
      {
        nixfleet.sambaClient = {
          enable = true;
          mounts = [
            {
              share = "media";
              mountpoint = "/home/test/shared/media";
              server = "203.0.113.10";
              readOnly = true;
            }
          ];
        };
      }
    ];
    syncthing-default = mkStandaloneSystem [
      (scopesPath + "/modules/scopes/syncthing")
      (scopesPath + "/modules/scopes/impermanence")
    ];
    # nix-index is not covered here — the scope references options
    # declared by the external nix-index-database module which isn't a
    # flake input of nixfleet-scopes. Consumer tests (e.g. in fleet)
    # cover it alongside that module.
    nix-ld-default = mkStandaloneSystem [
      (scopesPath + "/modules/scopes/nix-ld")
    ];
    nix-ld-enabled = mkStandaloneSystem [
      (scopesPath + "/modules/scopes/nix-ld")
      {nixfleet.nixLd.enable = true;}
    ];
    graphical-base-default = mkStandaloneSystem [
      (scopesPath + "/modules/scopes/graphical-base")
    ];
    graphical-base-enabled = mkStandaloneSystem [
      (scopesPath + "/modules/scopes/graphical-base")
      {nixfleet.graphical.variant = "gnome";}
    ];
    monitoring-blackbox-enabled = mkStandaloneSystem [
      (scopesPath + "/modules/scopes/monitoring-server")
      (scopesPath + "/modules/scopes/impermanence")
      {
        nixfleet.monitoring.server = {
          enable = true;
          blackbox = {
            enable = true;
            probes = [
              {
                name = "forge";
                target = "http://localhost:3001";
                module = "http_2xx";
              }
            ];
          };
          alerts.coordinator = true;
        };
      }
    ];

    # A.3 coordinator scopes — default eval (inert) + sample enabled config.
    tpm-keyslot-default = mkStandaloneSystem [
      (scopesPath + "/modules/scopes/tpm-keyslot")
      (scopesPath + "/modules/scopes/impermanence")
    ];
    tpm-keyslot-enabled = mkStandaloneSystem [
      (scopesPath + "/modules/scopes/tpm-keyslot")
      (scopesPath + "/modules/scopes/impermanence")
      {nixfleet.tpmKeyslot.enable = true;}
    ];
    forge-default = mkStandaloneSystem [
      (scopesPath + "/modules/scopes/forge")
      (scopesPath + "/modules/scopes/impermanence")
    ];
    forge-enabled = mkStandaloneSystem [
      (scopesPath + "/modules/scopes/forge")
      (scopesPath + "/modules/scopes/impermanence")
      {
        nixfleet.forge = {
          enable = true;
          domain = "git.test.internal";
        };
      }
    ];
    ci-runner-default = mkStandaloneSystem [
      (scopesPath + "/modules/scopes/ci-runner")
      (scopesPath + "/modules/scopes/impermanence")
    ];
    ci-runner-forgejo = mkStandaloneSystem [
      (scopesPath + "/modules/scopes/ci-runner")
      (scopesPath + "/modules/scopes/impermanence")
      {
        nixfleet.ciRunner.forgejoActions = {
          enable = true;
          registrationTokenFile = "/run/secrets/fake";
        };
      }
    ];
    reverse-proxy-default = mkStandaloneSystem [
      (scopesPath + "/modules/scopes/reverse-proxy")
      (scopesPath + "/modules/scopes/impermanence")
    ];
    reverse-proxy-enabled = mkStandaloneSystem [
      (scopesPath + "/modules/scopes/reverse-proxy")
      (scopesPath + "/modules/scopes/impermanence")
      {
        nixfleet.reverseProxy = {
          enable = true;
          sites = [
            {
              host = "git.test.internal";
              upstream = "localhost:3001";
            }
          ];
        };
      }
    ];
    backup-server-default = mkStandaloneSystem [
      (scopesPath + "/modules/scopes/backup-server")
      (scopesPath + "/modules/scopes/impermanence")
    ];
    backup-server-enabled = mkStandaloneSystem [
      (scopesPath + "/modules/scopes/backup-server")
      (scopesPath + "/modules/scopes/impermanence")
      {
        nixfleet.backupServer = {
          enable = true;
          domain = "restic.test.internal";
          prune.enable = false;
        };
      }
    ];
  };

  # Force a few representative options per role to exercise the eval path.
  checks = [
    # Workstation: HM + firewall + secrets on, backup off
    (roles.workstation.config.nixfleet.home-manager.enable == true)
    (roles.workstation.config.nixfleet.firewall.enable == true)
    (roles.workstation.config.nixfleet.secrets.enable == true)
    (roles.workstation.config.nixfleet.backup.enable == false)

    # Workstation: operators roleGroups merged with isAdmin wheel
    # roleGroups=["networkmanager" "video" "audio" "docker"], isAdmin=true
    # → extraGroups = ["networkmanager" "video" "audio" "docker" "wheel"]
    (builtins.elem "wheel" roles.workstation.config.users.users.testuser.extraGroups)
    (builtins.elem "networkmanager" roles.workstation.config.users.users.testuser.extraGroups)
    (builtins.elem "video" roles.workstation.config.users.users.testuser.extraGroups)
    (builtins.elem "audio" roles.workstation.config.users.users.testuser.extraGroups)
    (builtins.elem "docker" roles.workstation.config.users.users.testuser.extraGroups)

    # Server: firewall + monitoring on, HM off (role doesn't import HM scope)
    (roles.server.config.nixfleet.firewall.enable == true)
    (roles.server.config.nixfleet.monitoring.nodeExporter.enable == true)
    (roles.server.config.nixfleet.secrets.identityPaths.enableUserKey == false)

    # Server: roleGroups=[], isAdmin=true → only wheel
    (builtins.elem "wheel" roles.server.config.users.users.testuser.extraGroups)
    (roles.server.config.users.users.testuser.extraGroups == ["wheel"])

    # Endpoint: secrets on (role doesn't force firewall either way)
    (roles.endpoint.config.nixfleet.secrets.enable == true)

    # Endpoint: operators options are available
    (roles.endpoint.config.nixfleet.operators.primaryUser == "testuser")

    # microvm-guest: nftables NOT enabled (firewall scope not imported by role)
    (roles.microvm-guest.config.networking.nftables.enable == false)

    # Secrets resolvedIdentityPaths always computed, independent of enable
    (builtins.isList roles.workstation.config.nixfleet.secrets.resolvedIdentityPaths)

    # Operators: _primaryName resolves to "testuser" across roles
    (roles.workstation.config.nixfleet.operators._primaryName == "testuser")
    (roles.server.config.nixfleet.operators._primaryName == "testuser")

    # base.terminfo (new name): default on
    (roles.server.config.nixfleet.base.terminfo.enable == true)
    (roles.workstation.config.nixfleet.base.terminfo.enable == true)
    # Renamed option shim: reading the legacy name still works
    (roles.server.config.nixfleet.terminalCompat.enable == true)
    (roles.workstation.config.nixfleet.terminalCompat.enable == true)

    # Generation label: enabled on server + workstation
    (roles.server.config.nixfleet.generationLabel.enable == true)
    (roles.workstation.config.nixfleet.generationLabel.enable == true)

    # O11y metrics: enabled on server + workstation
    (roles.server.config.nixfleet.o11y.metrics.enable == true)
    (roles.workstation.config.nixfleet.o11y.metrics.enable == true)

    # O11y logs: off by default
    (roles.server.config.nixfleet.o11y.logs.enable == false)

    # Hardware: options available on server + workstation
    (roles.server.config.nixfleet.hardware.nvidia.enable == false)
    (roles.workstation.config.nixfleet.hardware.cpu.vendor == null)

    # Hardware: both boot flags default to false
    (roles.server.config.nixfleet.hardware.legacyBoot == false)
    (roles.server.config.nixfleet.hardware.secureBoot == false)

    # Hardware: bluetooth/nvidia/wol off by default
    (roles.server.config.nixfleet.hardware.bluetooth.enable == false)
    (roles.workstation.config.nixfleet.hardware.nvidia.enable == false)
    (roles.workstation.config.nixfleet.hardware.wol.enable == false)

    # Hardware: zramSwap on for workstation, off for server
    (roles.workstation.config.nixfleet.hardware.memory.zramSwap == true)
    (roles.server.config.nixfleet.hardware.memory.zramSwap == false)

    # Standalone scope evals don't throw
    (standalone.vpn.config.nixfleet.vpn.enable == false)
    (standalone.compliance.config.nixfleet.compliance.enable == false)
    (standalone.remote-builders.config.nixfleet.distributedBuilds.enable == false)
    (standalone.monitoring-server.config.nixfleet.monitoring.server.enable == false)

    # A.2 scopes default + enabled
    (standalone.tailscale-default.config.nixfleet.tailscale.enable == false)
    (standalone.tailscale-enabled.config.services.tailscale.enable == true)
    (standalone.samba-client-default.config.nixfleet.sambaClient.enable == false)
    (standalone.samba-client-enabled.config.nixfleet.sambaClient.mounts != [])
    (standalone.syncthing-default.config.nixfleet.syncthing.enable == false)
    (standalone.nix-ld-default.config.nixfleet.nixLd.enable == false)
    (standalone.nix-ld-enabled.config.programs.nix-ld.enable == true)
    (standalone.graphical-base-default.config.nixfleet.graphical.enable == false)
    (standalone.graphical-base-enabled.config.nixfleet.graphical.enable == true)
    (standalone.graphical-base-enabled.config.nixfleet.graphical.protocol == "wayland")
    (standalone.monitoring-blackbox-enabled.config.services.prometheus.exporters.blackbox.enable == true)

    # A.3 coordinator scopes default + enabled
    (standalone.tpm-keyslot-default.config.nixfleet.tpmKeyslot.enable == false)
    (standalone.tpm-keyslot-enabled.config.security.tpm2.enable == true)
    (standalone.forge-default.config.nixfleet.forge.enable == false)
    (standalone.forge-enabled.config.services.forgejo.enable == true)
    (standalone.ci-runner-default.config.nixfleet.ciRunner.forgejoActions.enable == false)
    (standalone.ci-runner-forgejo.config.services.gitea-actions-runner.instances.nixfleet.enable == true)
    (standalone.reverse-proxy-default.config.nixfleet.reverseProxy.enable == false)
    (standalone.reverse-proxy-enabled.config.services.caddy.enable == true)
    (standalone.backup-server-default.config.nixfleet.backupServer.enable == false)
    (standalone.backup-server-enabled.config.systemd.services.restic-rest-server.enable or true)
  ];

  allPass = lib.all (x: x == true) checks;
in
  assert allPass;
    pkgs.runCommand "nixfleet-scopes-eval-check" {passthru = {inherit roles;};} ''
      echo "eval OK for ${toString (lib.length checks)} role/scope assertions"
      touch $out
    ''
