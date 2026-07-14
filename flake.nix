{
  description = "Kicad version";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs-kicad.url = "github:nixos/nixpkgs?ref=nixos-25.05";
  };

  outputs = { self, nixpkgs, nixpkgs-kicad }:
    let
      system = "x86_64-linux";
      # pkgs = import nixpkgs { inherit system; };
      pkgs = nixpkgs.legacyPackages.${system};
      kicadPkgs = import nixpkgs-kicad { inherit system; };
    in
    {
      devShells."x86_64-linux".default = pkgs.mkShell {
        # packages = [ pkgs.kicad ];
        packages = [ kicadPkgs.kicad ];
    };
  };
}
