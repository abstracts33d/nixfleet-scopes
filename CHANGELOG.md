# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/). Versioning: [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Changed

- `terminal-compat` scope merged into `base`. `kitty.terminfo` + `alacritty.terminfo` are now gated by `nixfleet.base.terminfo.enable` (default `true`); `curl`, `wget`, `unzip` moved to base's unconditional package set. Roles no longer import `terminal-compat`.

### Deprecated

- `nixfleet.terminalCompat.enable` is aliased to `nixfleet.base.terminfo.enable` via `lib.mkRenamedOptionModule` for one release; remove usages on the consumer side.

### Removed

- `modules/scopes/terminal-compat/` directory + `terminal-compat` exports from `flake.scopes` / `flake.nixosModules`.

## [0.1.0] - 2026-04-19

Initial release.

[Unreleased]: https://github.com/arcanesys/nixfleet-scopes/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/arcanesys/nixfleet-scopes/releases/tag/v0.1.0
