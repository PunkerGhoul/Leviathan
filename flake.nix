{
  description = "Leviathan";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    nixgl.url = "github:guibou/nixGL";
  };

  outputs = { self, nixpkgs, home-manager, nixgl, ... }:
    let
      system = "x86_64-linux";
      overlays = [ nixgl.overlay ];
      pkgs = import nixpkgs { inherit system overlays; };
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
        program = "${self.homeConfigurations.ghoul.activationPackage}/activate";
      };
    };
}
