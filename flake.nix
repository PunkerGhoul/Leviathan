{
  description = "Leviathan";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixgl.url = "github:guibou/nixGL";
  };

  outputs = { self, nixpkgs, home-manager, nixgl, ... }:
    let
      system = "x86_64-linux";
      overlays = [ nixgl.overlay ];
      pkgs = import nixpkgs { inherit system overlays; };
      homeManagerBin = "${home-manager.packages.${system}.home-manager}/bin/home-manager";
      applyLeviathan = pkgs.writeShellApplication {
        name = "apply-leviathan";
        runtimeInputs = [ home-manager.packages.${system}.home-manager ];
        text = ''
          exec ${homeManagerBin} switch --flake ${self}#ghoul -b backup "$@"
        '';
      };
    in
    {
      homeConfigurations.ghoul = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./home.nix ];
        extraSpecialArgs = {
          inherit nixgl system;
        };
      };

      defaultApp.x86_64-linux = {
        type = "app";
        program = "${applyLeviathan}/bin/apply-leviathan";
      };
    };
}
