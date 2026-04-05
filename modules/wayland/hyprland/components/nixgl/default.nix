{ config, lib, pkgs }:

let
  defaultNixGLScript =
    {
      mesa = "nixGLMesa";
      mesaPrime = "nixGLMesaPrime";
      nvidia = "nixGLNvidia";
      nvidiaPrime = "nixGLNvidiaPrime";
    }.${config.targets.genericLinux.nixGL.defaultWrapper};

  hyprlandWrapper = pkgs.replaceVars ./scripts/hyprland-wrapper.sh {
    bash = "${pkgs.bash}/bin/bash";
    coreutils = "${pkgs.coreutils}/bin";
    homeDirectory = config.home.homeDirectory;
  };

  hyprlandBuilder = pkgs.replaceVars ./scripts/build-hyprland-session.sh {
    bash = "${pkgs.bash}/bin/bash";
    coreutils = "${pkgs.coreutils}/bin";
    gnused = "${pkgs.gnused}/bin/sed";
  };

  mkHyprlandPackage = { enableXWayland ? true }:
    let
      hyprlandBase = pkgs.hyprland.override { inherit enableXWayland; };
      hyprlandWrapped = config.lib.nixGL.wrap hyprlandBase;
    in
    pkgs.stdenvNoCC.mkDerivation {
      pname = "hyprland-nixgl-session";
      version = hyprlandBase.version;
      dontUnpack = true;
      builder = hyprlandBuilder;
      inherit hyprlandWrapped hyprlandWrapper;
    };
in
{
  hyprlandPackage = lib.makeOverridable mkHyprlandPackage { };

  nixGLCompat = pkgs.writeShellScriptBin "nixGL" ''
    exec ${defaultNixGLScript} "$@"
  '';

  nixGLIntelCompat = pkgs.writeShellScriptBin "nixGL-intel" ''
    exec nixGLMesa "$@"
  '';

  primeRunCompat = pkgs.writeShellScriptBin "prime-run" ''
    exec prime-offload "$@"
  '';
}