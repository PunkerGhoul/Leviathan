{ pkgs, nixgl, lib, ... }:

{
  home.stateVersion = "25.11";

  home.username = "ghoul";
  home.homeDirectory = "/home/ghoul";

  targets.genericLinux.nixGL = {
    packages = nixgl.packages;
    defaultWrapper = "mesa";
    offloadWrapper = "mesaPrime";
    # Keep the compositor on the iGPU and expose only pure wrappers.
    installScripts = [ "mesa" "mesaPrime" ];
    # Install a PRIME offload helper for host applications on hybrid systems.
    prime.installScript = "nvidia";
  };

  programs.zsh.enable = true;
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

  imports = [
    ./modules
  ];
}
