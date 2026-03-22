{ config, pkgs, ... }:

{
  home.stateVersion = "25.11";

  home.username = "ghoul";
  home.homeDirectory = "/home/ghoul";

  programs.zsh.enable = true;
  programs.git.enable = true;

}
