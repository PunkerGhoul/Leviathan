{ config, lib, pkgs, ... }:

{
  imports = [
    (import ./wayland { inherit config pkgs; })
  ];
}
