# Lista centralizada de paquetes necesarios para Hyprland
# Separados por categoría para mejor mantenimiento

{ pkgs, scripts }:
{
  # Desktop environment
  hyprland = with pkgs; [
    hyprlock
    hyprshot
    wofi
    kitty
    ironbar
  ];

  # System tools
  system = with pkgs; [
    bluez
    blueman
    networkmanager
    networkmanagerapplet
    fzf
    procps
  ];

  # User tools
  utilities = with pkgs; [
    pavucontrol
    waypaper
    xfce4-power-manager
    wirelesstools
  ];

  # Typography
  fonts = with pkgs; [
    nerd-fonts.symbols-only
  ];

  # Aggregated list for home.packages
  all = with pkgs; [
    # Hyprland environment
    hyprlock
    hyprshot
    wofi
    kitty
    ironbar

    # System tools
    bluez
    blueman
    networkmanager
    networkmanagerapplet
    fzf
    procps

    # User tools
    pavucontrol
    waypaper
    xfce4-power-manager
    wirelesstools

    # Typography
    nerd-fonts.symbols-only
  ] ++ scripts.allScripts;
}
