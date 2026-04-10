# Leviathan Updates Manager (Rust)

This project manages the lifecycle of the updates stage:

- `install`
- `uninstall`
- `status`

It installs/removes systemd units from templates in `stages/updates/` and links the
`leviathan-updates-agent` binary from the Nix Store.

Manual build:

```bash
nix build .#updates-manager
```
