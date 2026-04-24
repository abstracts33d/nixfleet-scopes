# Base scope — option declarations.
{lib, ...}: {
  options.nixfleet.base = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install universal CLI tools on this host.";
    };

    terminfo.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install terminfo entries for modern terminal emulators (kitty, alacritty) on this host.";
    };
  };
}
