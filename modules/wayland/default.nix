{ config, pkgs, ... }:

{
  imports = [
    (import ./hyprland { inherit config pkgs; } )
  ];

  wayland = {
  };
}
