# Leviathan

Arch + Wayland + Hyprland + Nix

## Flakes

This repository is set up to be used as a pure Home Manager flake.

```bash
home-manager switch --flake .#ghoul -b backup
```

`--impure` should only be necessary if the configuration depends on external state such as:

- untracked files like `env.nix`
- environment variables read with `builtins.getEnv`
- paths outside the flake input graph

For `Leviathan`, Wayland/Hyprland is not a reason to use `--impure`.
