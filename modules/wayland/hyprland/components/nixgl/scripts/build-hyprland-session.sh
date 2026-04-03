#!@bash@

set -eu

@coreutils@/mkdir -p "$out"
@coreutils@/cp -r "$hyprlandWrapped"/. "$out"/
@coreutils@/chmod -R u+w "$out"
@coreutils@/mv "$out/bin/Hyprland" "$out/bin/Hyprland-real"
@coreutils@/install -Dm755 "$hyprlandWrapper" "$out/bin/Hyprland"

if [ -f "$out/share/wayland-sessions/hyprland.desktop" ]; then
  @gnused@ \
    "s|^Exec=.*$|Exec=$out/bin/Hyprland|" \
    "$out/share/wayland-sessions/hyprland.desktop" \
    > "$out/share/wayland-sessions/hyprland.desktop.tmp"
  @coreutils@/mv \
    "$out/share/wayland-sessions/hyprland.desktop.tmp" \
    "$out/share/wayland-sessions/hyprland.desktop"
fi
