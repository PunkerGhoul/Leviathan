{ pkgs, nixgl, lib, ... }:

{
  home.stateVersion = "25.11";

  home.username = "ghoul";
  home.homeDirectory = "/home/ghoul";

  targets.genericLinux.nixGL = {
    packages = nixgl.packages;
    defaultWrapper = "mesa";
  };

  programs.zsh.enable = true;
  programs.zsh.loginExtra = ''
    if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ] && [ "''${XDG_VTNR:-}" = "1" ]; then
      if command -v uwsm >/dev/null 2>&1 && uwsm check may-start; then
        if ! uwsm start -- start-hyprland >> "$HOME/.local/state/uwsm-start.log" 2>&1; then
          echo "uwsm failed to start Hyprland. See $HOME/.local/state/uwsm-start.log" >&2
        fi
      fi
    fi
  '';
  programs.git.enable = true;

  home.activation.setDefaultShell = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    current_shell="$(${pkgs.gnugrep}/bin/grep "^$USER:" /etc/passwd | ${pkgs.coreutils}/bin/cut -d: -f7)"
    target_shell="${pkgs.zsh}/bin/zsh"

    if [ "$current_shell" != "$target_shell" ]; then
      if [ -x /usr/bin/sudo ]; then
        if ! ${pkgs.gnugrep}/bin/grep -qxF "$target_shell" /etc/shells; then
          $DRY_RUN_CMD /usr/bin/sudo /bin/sh -c \
            "${pkgs.coreutils}/bin/printf '%s\n' '$target_shell' >> /etc/shells"
        fi
        $DRY_RUN_CMD /usr/bin/sudo chsh -s "$target_shell" "$USER"
      else
        echo "sudo is required to set zsh as the default shell for $USER" >&2
        exit 1
      fi
    fi
  '';

  home.activation.reloadUserSystemdForUwsm = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    if [ -n "$XDG_RUNTIME_DIR" ] && [ -S "$XDG_RUNTIME_DIR/systemd/private" ]; then
      ${pkgs.systemd}/bin/systemctl --user daemon-reload || true
    fi
  '';

  home.file.".config/systemd/user/app-graphical.slice".source =
    "${pkgs.uwsm}/lib/systemd/user/app-graphical.slice";
  home.file.".config/systemd/user/background-graphical.slice".source =
    "${pkgs.uwsm}/lib/systemd/user/background-graphical.slice";
  home.file.".config/systemd/user/session-graphical.slice".source =
    "${pkgs.uwsm}/lib/systemd/user/session-graphical.slice";
  home.file.".config/systemd/user/wayland-session-bindpid@.service".source =
    "${pkgs.uwsm}/lib/systemd/user/wayland-session-bindpid@.service";
  home.file.".config/systemd/user/wayland-session-envelope@.target".source =
    "${pkgs.uwsm}/lib/systemd/user/wayland-session-envelope@.target";
  home.file.".config/systemd/user/wayland-session-pre@.target".source =
    "${pkgs.uwsm}/lib/systemd/user/wayland-session-pre@.target";
  home.file.".config/systemd/user/wayland-session-shutdown.target".source =
    "${pkgs.uwsm}/lib/systemd/user/wayland-session-shutdown.target";
  home.file.".config/systemd/user/wayland-session-waitenv.service".source =
    "${pkgs.uwsm}/lib/systemd/user/wayland-session-waitenv.service";
  home.file.".config/systemd/user/wayland-session-xdg-autostart@.target".source =
    "${pkgs.uwsm}/lib/systemd/user/wayland-session-xdg-autostart@.target";
  home.file.".config/systemd/user/wayland-wm-env@.service".source =
    "${pkgs.uwsm}/lib/systemd/user/wayland-wm-env@.service";
  home.file.".config/systemd/user/wayland-wm@.service".source =
    "${pkgs.uwsm}/lib/systemd/user/wayland-wm@.service";

  imports = [
    ./modules
  ];
}
