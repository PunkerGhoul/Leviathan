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
        exec uwsm start hyprland.desktop
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
          $DRY_RUN_CMD /usr/bin/sudo ${pkgs.coreutils}/bin/sh -c \
            "${pkgs.coreutils}/bin/printf '%s\n' '$target_shell' >> /etc/shells"
        fi
        $DRY_RUN_CMD /usr/bin/sudo chsh -s "$target_shell" "$USER"
      else
        echo "sudo is required to set zsh as the default shell for $USER" >&2
        exit 1
      fi
    fi
  '';

  imports = [
    ./modules
  ];
}
