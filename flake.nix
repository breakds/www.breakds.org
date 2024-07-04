{
  description = "www.breakds.org the website";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/24.05";

    utils.url = "github:numtide/flake-utils";
    utils.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, ... }@inputs: inputs.utils.lib.eachSystem [
    "x86_64-linux" "i686-linux" "aarch64-linux" "x86_64-darwin"
  ] (system:
    let pkgs = import nixpkgs {
          inherit system;
        };
    in {
      # Instantiate the development environment with CUDA 11.2
      devShell = pkgs.mkShell {
        name = "hugo-dev";

        packages = with pkgs; [ hugo go gcc libcap ];
      };

      defaultPackage = pkgs.stdenv.mkDerivation {
        name = "www-breakds-org";
        version = "2021.07.10";

        srcs = ./.;

        buildInputs = with pkgs; [ hugo go gcc libcap git ];

        buildPhase = ''
          hugo
        '';

        installPhase = ''
          cp -r public $out
        '';
      };
    });
}
