{
  description = "EarthRescue Love2D Geliştirme Ortamı";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            love               
            lua                 
    
            lua-language-server 
            selene             
          ];

          shellHook = ''
            echo "EarthRescue Welcome to the LÖVE2D Development Environment!"
            echo "LÖVE Verison: $(love --version)"
          '';
        };
      }
    );
}