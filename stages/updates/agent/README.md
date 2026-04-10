# Leviathan Updates Agent (Rust)

This project builds the `leviathan-updates-agent` binary using Nix.

The agent auto-detects:

- `username` (via `getuid` + `getpwuid`)
- `hostname` (via `gethostname`)

It is installed and uninstalled via flake apps:

- `nix run .#updates-install`
- `nix run .#updates-uninstall`

Manual build:

```bash
nix build .#updates-agent
```
