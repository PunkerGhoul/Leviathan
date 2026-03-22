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

  imports = [
    (import ./modules { inherit config lib pkgs env; })
  ];
}
