# TPM-backed ed25519 keyslot.
# A first-boot one-shot service creates an ed25519 primary under the
# owner hierarchy with sign-only attributes, evicts it to a persistent
# handle, and exports the public key (PEM + raw 32 bytes) to a
# configured directory. Idempotent: re-running after an impermanence
# wipe re-extracts the pubkey from the persisted handle without
# generating a new key.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.nixfleet.tpmKeyslot;
  pubkeyPem = "${cfg.exportPubkeyDir}/pubkey.pem";
  pubkeyRaw = "${cfg.exportPubkeyDir}/pubkey.raw";

  signWrapper = pkgs.writeShellApplication {
    name = cfg.signWrapperName;
    runtimeInputs = [pkgs.tpm2-tools];
    text = ''
      set -euo pipefail
      if [ $# -ne 1 ]; then
        echo "usage: ${cfg.signWrapperName} <file>" >&2
        exit 2
      fi
      tpm2_sign -c ${cfg.handle} -g sha256 -o - "$1"
    '';
  };
in {
  imports = [./options.nix];

  config = lib.mkIf cfg.enable {
    security.tpm2 = {
      enable = true;
      tctiEnvironment.enable = true;
    };

    environment.systemPackages = [
      pkgs.tpm2-tools
      signWrapper
    ];

    systemd.services.nixfleet-tpm-keyslot-provision = {
      description = "Provision TPM-backed ed25519 keyslot at ${cfg.handle}";
      wantedBy = ["multi-user.target"];
      after = ["tpm2-abrmd.service" "basic.target"];
      wants = ["tpm2-abrmd.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        StateDirectory = baseNameOf cfg.exportPubkeyDir;
      };
      path = [pkgs.tpm2-tools pkgs.openssl pkgs.coreutils];
      script = ''
        set -euo pipefail
        mkdir -p ${cfg.exportPubkeyDir}

        extract_raw() {
          openssl pkey -pubin -in ${pubkeyPem} -outform DER | tail -c 32 > ${pubkeyRaw}
          chmod 644 ${pubkeyPem} ${pubkeyRaw}
        }

        if tpm2_readpublic -c ${cfg.handle} -f pem -o ${pubkeyPem} 2>/dev/null; then
          extract_raw
          echo "Keyslot already persisted at ${cfg.handle}"
          exit 0
        fi

        tpm2_createprimary \
          --hierarchy o \
          --key-algorithm ${cfg.algorithm} \
          --attributes 'fixedtpm|fixedparent|sensitivedataorigin|userwithauth|sign' \
          --key-context /tmp/nixfleet-tpm-keyslot.ctx
        tpm2_evictcontrol --hierarchy o --object-context /tmp/nixfleet-tpm-keyslot.ctx ${cfg.handle}
        tpm2_readpublic -c ${cfg.handle} -f pem -o ${pubkeyPem}
        extract_raw
        rm -f /tmp/nixfleet-tpm-keyslot.ctx
        echo "Keyslot provisioned at ${cfg.handle}"
      '';
    };

    environment.persistence."/persist".directories = lib.mkIf (config.nixfleet.impermanence.enable or false) [
      {
        directory = cfg.exportPubkeyDir;
        mode = "0755";
      }
    ];
  };
}
