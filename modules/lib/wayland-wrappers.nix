# Pure helpers for wrapping Electron / JetBrains apps with the flags
# they need under Wayland. When isWayland is false, returns the package
# unchanged.
#
# Usage:
#   let w = inputs.nixfleet-scopes.lib.waylandWrappers {
#         inherit pkgs;
#         isWayland = osConfig.nixfleet.graphical.protocol == "wayland";
#       };
#   in w.wrapElectron pkgs.vscode "code"
{
  pkgs,
  isWayland,
}: let
  waylandElectronFlags = "--ozone-platform=wayland --enable-features=UseOzonePlatform,WaylandWindowDecorations";
in {
  wrapElectron = pkg: binName:
    if isWayland
    then
      pkg.overrideAttrs (old: {
        nativeBuildInputs = (old.nativeBuildInputs or []) ++ [pkgs.makeWrapper];
        postFixup =
          (old.postFixup or "")
          + ''
            wrapProgram $out/bin/${binName} --add-flags "${waylandElectronFlags}"
          '';
      })
    else pkg;

  wrapJetBrains = pkg: binName:
    if isWayland
    then
      pkg.overrideAttrs (old: {
        nativeBuildInputs = (old.nativeBuildInputs or []) ++ [pkgs.makeWrapper];
        postFixup =
          (old.postFixup or "")
          + ''
            wrapProgram $out/bin/${binName} --set _JAVA_AWT_WM_NONREPARENTING 1 --prefix _JAVA_OPTIONS " " "-Dawt.toolkit.name=WLToolkit"
          '';
      })
    else pkg;
}
