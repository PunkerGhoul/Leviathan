#!@bash@

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}"
log_file="$state_dir/hyprland.log"

@coreutils@/mkdir -p "$state_dir"
echo "=== $(@coreutils@/date -Is) starting Hyprland ===" >> "$log_file"

script_dir="$(CDPATH= cd -- "$(@coreutils@/dirname -- "$0")" && pwd)"

if [ "$#" -gt 0 ]; then
  exec "$script_dir/Hyprland-real" "$@"
fi

exec "$script_dir/Hyprland-real" >> "$log_file" 2>&1
