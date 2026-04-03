{ pkgs }:
{
  arch = pkgs.writeShellScriptBin "leviathan-arch-button" ''
    ${pkgs.coreutils}/bin/printf '󰣇\n'
  '';

  terminal = pkgs.writeShellScriptBin "leviathan-quick-terminal" ''
    ${pkgs.coreutils}/bin/printf '\n'
  '';

  files = pkgs.writeShellScriptBin "leviathan-quick-files" ''
    ${pkgs.coreutils}/bin/printf '󰉋\n'
  '';

  browser = pkgs.writeShellScriptBin "leviathan-quick-browser" ''
    ${pkgs.coreutils}/bin/printf '󰖟\n'
  '';

  wallpaper = pkgs.writeShellScriptBin "leviathan-quick-wallpaper" ''
    ${pkgs.coreutils}/bin/printf '󰸉\n'
  '';

  screenshot = pkgs.writeShellScriptBin "leviathan-quick-screenshot" ''
    ${pkgs.coreutils}/bin/printf '󰄀\n'
  '';

  settings = pkgs.writeShellScriptBin "leviathan-quick-settings" ''
    ${pkgs.coreutils}/bin/printf '󰒓\n'
  '';
}
