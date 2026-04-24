# TPM-backed signing keyslot. Supports ECDSA P-256 (default, widely
# supported by commodity TPMs) and ed25519 (requires TPM ECC curve 0x0040
# — rare on commercial hardware).
#
# A first-boot one-shot service creates a primary under the owner
# hierarchy with sign-only attributes, evicts it to a persistent handle,
# and exports the public key (PEM + algorithm-specific raw bytes) to a
# configured directory. Idempotent: re-running after an impermanence wipe
# re-extracts the pubkey from the persisted handle without generating a
# new key.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.nixfleet.tpmKeyslot;
  pubkeyPem = "${cfg.exportPubkeyDir}/pubkey.pem";
  pubkeyRaw = "${cfg.exportPubkeyDir}/pubkey.raw";

  # Per-algorithm config.
  algo =
    {
      "ecdsa-p256" = {
        # tpm2-tools shorthand for NIST P-256 ECC primary with sha256 hash.
        createPrimaryArgs = "--key-algorithm ecc256:ecdsasha256";
        # DER SubjectPublicKeyInfo for EC prime256v1 ends with a 65-byte
        # uncompressed point (0x04 || X || Y). Extract the last 64 bytes
        # (X || Y) as the raw representation consumers typically pin.
        extractRawCmd = ''
          openssl ec -pubin -in ${pubkeyPem} -pubout -outform DER \
            | tail -c 64 > ${pubkeyRaw}
        '';
        tpmSignHashArg = "-g sha256";
      };
      "ed25519" = {
        createPrimaryArgs = "--key-algorithm ed25519";
        # For ed25519 the raw pubkey is 32 bytes at the tail of the DER SPKI.
        extractRawCmd = ''
          openssl pkey -pubin -in ${pubkeyPem} -outform DER | tail -c 32 > ${pubkeyRaw}
        '';
        tpmSignHashArg = "-g sha256";
      };
    }.${
      cfg.algorithm
    };

  signWrapper = pkgs.writeShellApplication {
    name = cfg.signWrapperName;
    runtimeInputs = [pkgs.tpm2-tools];
    text = ''
      set -euo pipefail
      if [ $# -ne 1 ]; then
        echo "usage: ${cfg.signWrapperName} <file>" >&2
        exit 2
      fi
      tpm2_sign -c ${cfg.handle} ${algo.tpmSignHashArg} -o - "$1"
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
      description = "Provision TPM-backed ${cfg.algorithm} keyslot at ${cfg.handle}";
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
          ${algo.extractRawCmd}
          chmod 644 ${pubkeyPem} ${pubkeyRaw}
        }

        if tpm2_readpublic -c ${cfg.handle} -f pem -o ${pubkeyPem} 2>/dev/null; then
          extract_raw
          echo "Keyslot already persisted at ${cfg.handle}"
          exit 0
        fi

        tpm2_createprimary \
          --hierarchy o \
          ${algo.createPrimaryArgs} \
          --attributes 'fixedtpm|fixedparent|sensitivedataorigin|userwithauth|sign' \
          --key-context /tmp/nixfleet-tpm-keyslot.ctx
        tpm2_evictcontrol --hierarchy o --object-context /tmp/nixfleet-tpm-keyslot.ctx ${cfg.handle}
        tpm2_readpublic -c ${cfg.handle} -f pem -o ${pubkeyPem}
        extract_raw
        rm -f /tmp/nixfleet-tpm-keyslot.ctx
        echo "${cfg.algorithm} keyslot provisioned at ${cfg.handle}"
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
