# Graphical-base — aggregates options + NixOS plumbing + audio + fonts + Wayland env.
{...}: {
  imports = [
    ./options.nix
    ./nixos.nix
    ./audio.nix
    ./fonts.nix
    ./wayland.nix
  ];
}
