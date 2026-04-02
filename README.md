# Leviathan

Arch + Wayland + Hyprland + Nix

## Flakes

This repository is set up to be used as a pure Home Manager flake.

```bash
nix run .
```

This is the recommended entrypoint because it uses the `home-manager` bundled by the flake itself, so it works even if `home-manager` is not installed globally.

If you already have `home-manager` in your `PATH`, this remains equivalent:

```bash
home-manager switch --flake .#ghoul -b backup
```

`--impure` should only be necessary if the configuration depends on external state such as:

- untracked files like `env.nix`
- environment variables read with `builtins.getEnv`
- paths outside the flake input graph

For `Leviathan`, Wayland/Hyprland is not a reason to use `--impure`.

## Optimus / Hybrid GPUs

`Leviathan` keeps the Hyprland session on the iGPU by default through `nixGLMesa`,
which is the safest setup for hybrid Intel + NVIDIA laptops.

The flake also installs pure helper commands for the common Optimus flows:

```bash
nixGL-intel <app>
prime-run <app>
prime-offload <app>
```

Recommended usage:

- Run `Hyprland` itself on Intel/iGPU.
- Launch host-installed GPU-heavy apps on NVIDIA with `prime-run` or `prime-offload`.

This project does not install the proprietary NVIDIA driver or CUDA toolkit.
Those still come from the host system (for example Arch packages such as
`nvidia-open-dkms`, `nvidia-utils`, and `cuda`).
