{ config, lib, pkgs, env, ... }:

{
  imports = [
    (import ./wayland { inherit config pkgs; })
  ];
}
