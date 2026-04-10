# Updates Stage Layout

This stage is split to keep concerns separated:

- `agent/`: Rust source project (`Cargo.toml`, `Cargo.lock`, `src/`, optional `target/`).
- `manager/`: Rust source project for stage lifecycle (`install`, `uninstall`, `status`).
- `units/service.unit`: systemd service template for install.
- `units/timer.unit`: systemd timer template for install.
- `default.nix`: stage wiring (`install`, `uninstall`, `status`).

Both Rust crates are built via nixpkgs `rustPlatform.buildRustPackage`.

Rollback safety:

- `updates-install` creates backups of existing systemd unit files when they are not Leviathan-managed.
- `updates-uninstall` restores those backups and previous timer enablement state when available.
- Username resolution for cache path is done from system identity (`SUDO_UID`/`SUDO_USER` + libc), not from `local/default.nix`.
- Runtime state (`state.env` and backups) stays in `/var/lib/leviathan/updates/state`; it cannot live in Nix Store because the store is immutable/read-only at runtime.
- If uninstall finds non-managed units without backup metadata, it aborts instead of deleting them.

Commands:

```bash
nix run .#updates-install
nix run .#updates-status
nix run .#updates-uninstall
```
