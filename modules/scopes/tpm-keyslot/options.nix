# TPM keyslot scope — option declarations.
{lib, ...}: {
  options.nixfleet.tpmKeyslot = {
    enable = lib.mkEnableOption "TPM2-backed ed25519 keyslot provisioned at first boot";

    handle = lib.mkOption {
      type = lib.types.str;
      default = "0x81010001";
      description = "TPM2 persistent handle for the generated key (TPM2_HT_PERSISTENT range).";
    };

    algorithm = lib.mkOption {
      type = lib.types.enum ["ed25519"];
      default = "ed25519";
      description = "Signing algorithm. Currently only ed25519 is supported.";
    };

    exportPubkeyDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/nixfleet-tpm-keyslot";
      description = "Directory where the exported public key files are written (PEM + raw).";
    };

    signWrapperName = lib.mkOption {
      type = lib.types.str;
      default = "tpm-sign";
      description = "Name of the shell wrapper installed system-wide that signs a file with the TPM-held key.";
    };
  };
}
