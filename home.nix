{ config, lib, pkgs, nixgl, ... }:

{
  home.stateVersion = "25.11";

  home.username = "ghoul";
  home.homeDirectory = "/home/ghoul";

  targets.genericLinux.nixGL = {
    packages = nixgl.packages;
    defaultWrapper = "mesa";
  };

  programs.zsh.enable = true;
  programs.git.enable = true;

  # `start-hyprland` checks for a `nixGL` executable on non-NixOS systems.
  # Installing it in the Home Manager profile satisfies that check.
  home.packages = [
    nixgl.packages.${pkgs.system}.nixgl
  ];

  imports = [
    (import ./modules { inherit config lib pkgs; })
  ];
}
