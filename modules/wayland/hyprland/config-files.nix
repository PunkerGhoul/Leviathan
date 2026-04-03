# Mapeo de archivos de configuración de Hyprland
# Esta modularización permite gestionar la configuración de forma centralizada

{ ... }:
{
  xdg.configFile = {
    # Archivos de tema
    "hypr/.current-theme".source = ./config/.current-theme;

    # Configuración principal
    "hypr/autostart.conf".source = ./config/autostart.conf;
    "hypr/input.conf".source = ./config/input.conf;
    "hypr/keybinds.conf".source = ./config/keybinds.conf;
    "hypr/look-and-feel.conf".source = ./config/look-and-feel.conf;
    "hypr/monitors.conf".source = ./config/monitors.conf;
    "hypr/programs.conf".source = ./config/programs.conf;
    "hypr/rules.conf".source = ./config/rules.conf;
    "hypr/variables.conf".source = ./config/variables.conf;

    # Configuración de programas relacionados
    "hypr/hypridle.conf".source = ./config/hypridle.conf;
    "hypr/hyprlock.conf".source = ./config/hyprlock.conf;
    "hypr/hyprshot.conf".source = ./config/hyprshot.conf;

    # Temas
    "hypr/themes" = {
      source = ./config/themes;
      recursive = true;
    };

    # Quickshell (barra de estado)
    "quickshell/shell.qml".source = ./components/quickshell/config/shell.qml;

    # Scripts
    "hypr/scripts/restart-quickshell.sh".source = ./components/quickshell/scripts/restart-quickshell.sh;
  };
}
