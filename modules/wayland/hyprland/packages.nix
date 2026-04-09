# Lista centralizada de paquetes necesarios para Hyprland
# Separados por categoría para mejor mantenimiento

{ pkgs, scripts }:
let
  hyprlockManaged = pkgs.symlinkJoin {
    name = "hyprlock-managed";
    paths = [ pkgs.hyprlock ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/hyprlock \
        --prefix LD_LIBRARY_PATH : /usr/lib
    '';
  };
in
{
  # Desktop environment
  hyprland = with pkgs; [
    hyprlockManaged
    hyprshot
    wofi
    kitty
    quickshell
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
    noto-fonts
  ];

  # Aggregated list for home.packages
  all = with pkgs; [
    # Hyprland environment
    hyprlockManaged
    hyprshot
    wofi
    kitty
    quickshell

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
    noto-fonts
  ] ++ scripts.allScripts;
}
