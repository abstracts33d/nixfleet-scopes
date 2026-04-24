# nix-ld: run dynamically-linked binaries (gems, npm, pip, etc.) on NixOS
# by providing a ld.so shim with a curated set of common shared libraries
# at the FHS-standard paths.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.nixfleet.nixLd;
in {
  options.nixfleet.nixLd = {
    enable = lib.mkEnableOption "nix-ld with a curated library set";

    extraLibraries = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Extra shared libraries to expose via nix-ld, on top of the curated baseline.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.nix-ld.enable = true;
    programs.nix-ld.libraries =
      (with pkgs; [
        stdenv.cc.cc
        zlib
        openssl
        glib
        libGL
      ])
      ++ cfg.extraLibraries;
  };
}
