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
        name = "zola-dev";

        packages = with pkgs; [ zola ];
      };

      defaultPackage = let

        abridge = pkgs.fetchFromGitHub {
          owner = "breakds";
          repo = "abridge";
          rev = "3165d6ca46249a8a4bc49e9c1846b108647803e1";
          hash = "sha256-LGlFdhBdA71HgB5AKDndbpcTgzYNC6vAmTGBeML1584=";
        };

      in pkgs.stdenv.mkDerivation {
        name = "www-breakds-org";
        version = "2024.08.25";

        srcs = ./.;

        buildInputs = with pkgs; [ zola ];

        postPatch = ''
          mkdir themes
          ln -s ${abridge} themes/abridge
        '';

        buildPhase = ''
          zola build
        '';

        installPhase = ''
          cp -r public $out
        '';
      };
    });
}
