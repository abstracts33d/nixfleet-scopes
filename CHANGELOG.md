# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/). Versioning: [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.2.0] - 2026-04-24

### Added

Extracted from `abstracts33d/fleet` as generic scopes:

- `tailscale` (+ `tailscaleDarwin`) — Tailscale mesh VPN with optional OAuth auto-auth.
- `ssh-deployDarwin` — passwordless-sudo scaffolding for `nixfleet` CLI SSH deploys on macOS.
- `samba-client` (+ `samba-clientDarwin`) — cross-platform SMB auto-mounts (NixOS systemd-automount, macOS launchd agent).
- `syncthing` (+ `syncthingDarwin`) — NixOS native service + macOS launchd agent driving the REST API.
- `nix-index` (+ `nix-indexHm`) — nix-index-database + comma + command-not-found replacement.
- `nix-ld` — nix-ld with a curated baseline library set and `extraLibraries` passthrough.
- `graphical-base` — DE-agnostic NixOS graphical plumbing (portals, input, keyring, PipeWire, fonts, Wayland env vars). Renamed option namespace to `nixfleet.graphical.*`.
- `monitoring-server/blackbox.nix` (folded into existing scope) — blackbox exporter + probe scrape job; `nixfleet.monitoring.server.blackbox.{enable, port, probes=[{name,target,module}]}`.

Library helpers:

- `flake.lib.waylandWrappers` — pure `wrapElectron` / `wrapJetBrains` helpers parameterised on `pkgs` + `isWayland`.

Platform extensions:

- `platform.darwin-base` gains a `nixfleet.darwin.homebrew.*` option tree (enable, user, taps, brews, casks, masApps, onActivation) — scaffolding only; consumers still import `inputs.nix-homebrew.darwinModules.nix-homebrew` alongside.

New coordinator scopes for NixFleet v0.2 Stream A:

- `tpm-keyslot` — first-boot TPM2-backed ed25519 keyslot provisioning + pubkey export + `tpm-sign` wrapper.
- `forge` — Forgejo (domain, http/ssh ports, actions, LFS, SMTP, bootstrap admin).
- `attic-server` — atticd wrapper (from the new `attic` flake input); TOML-rendered config, GC timer, persistence.
- `ci-runner` — Hercules CI agent and/or Forgejo Actions self-hosted runner.
- `reverse-proxy` — Caddy with internal/acme/off TLS modes per site and internal-CA root export.
- `backup-server` — restic-rest-server with append-only + optional local prune timer.
- `coordinator` — meta-scope; setting `nixfleet.coordinator.enable` cascades `lib.mkDefault` enable flags across the six scopes above.

Option extensions on existing scopes:

- `nixfleet.monitoring.server.alerts.coordinator` — emits forge/cache probe-based alerts and a CI runner up alert.
- `nixfleet.distributedBuilds.trust.coordinatorPubkey` — when set, appended to `nix.settings.trusted-public-keys` (CONTRACTS.md §II #2).
- `nixfleet.backup.restic.serverScope` — enum (`none | http-local | https-tailnet`) so clients of `backup-server` derive their repo URL shape uniformly.

### Changed

- `terminal-compat` scope merged into `base`. `kitty.terminfo` + `alacritty.terminfo` are now gated by `nixfleet.base.terminfo.enable` (default `true`); `curl`, `wget`, `unzip` moved to base's unconditional package set. Roles no longer import `terminal-compat`.

### Deprecated

- `nixfleet.terminalCompat.enable` is aliased to `nixfleet.base.terminfo.enable` via `lib.mkRenamedOptionModule` for one release; remove usages on the consumer side.

### Removed

- `modules/scopes/terminal-compat/` directory + `terminal-compat` exports from `flake.scopes` / `flake.nixosModules`.

### Infrastructure

- Added `attic` flake input (`github:booxter/attic/newer-nix`) consumed by the `attic-server` scope.
- Eval tests for every new scope (`tests/eval.nix`): default (inert) + sample-enabled shapes, except `nix-index` which depends on the external `nix-index-database` module.

## [0.1.0] - 2026-04-19

Initial release.

[Unreleased]: https://github.com/arcanesys/nixfleet-scopes/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/arcanesys/nixfleet-scopes/releases/tag/v0.2.0
[0.1.0]: https://github.com/arcanesys/nixfleet-scopes/releases/tag/v0.1.0
