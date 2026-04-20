# Contributing to NixFleet Scopes

Thank you for your interest in contributing!

## Development Setup

**Prerequisites:**
- [Nix](https://nixos.org/download) with flakes enabled (`experimental-features = nix-command flakes`)

**Getting started:**
```sh
git clone https://github.com/arcanesys/nixfleet-scopes.git
cd nixfleet-scopes
nix develop  # enters the dev shell with alejandra
```

## Running Checks

```sh
nix fmt                       # format all Nix files
nix flake check --no-build    # run eval tests without building derivations
```

## Adding a Scope

1. Create `modules/scopes/<name>/default.nix`
2. Declare options under `nixfleet.<name>.*`
3. Guard config with `lib.mkIf config.nixfleet.<name>.enable`
4. Wire the module in `modules/flake-module.nix`
5. Add eval tests in `tests/eval.nix`

See any existing scope in `modules/scopes/` for a working example.

## Adding a Role

1. Create `modules/roles/<name>.nix`
2. Import the relevant scopes
3. Set defaults with `lib.mkDefault`
4. Wire the role in `modules/flake-module.nix`
5. Add eval tests in `tests/eval.nix`

## Commit Conventions

Use [conventional commits](https://www.conventionalcommits.org/):

- `feat:` - new scope, role, or disk template
- `fix:` - bug fix
- `docs:` - documentation only
- `chore:` - maintenance, dependencies
- `test:` - test additions or fixes

## Pull Requests

1. Fork and create a feature branch
2. Ensure `nix fmt` and `nix flake check --no-build` pass
3. Open a PR against main
4. Maintainer reviews and merges

## License

By submitting a pull request, you agree to license your contribution under the [MIT License](LICENSE-MIT).
