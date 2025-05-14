{
  description = "Home Manager configuration";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-patch.url =
      "github:nixos/nixpkgs/b2b0718004cc9a5bca610326de0a82e6ea75920b";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    attic = {
      url = "github:zhaofengli/attic";
      # For some reason some of the later versions of nixpkgs cause an issue where it says
      # `fatal error: 'nix/config.h' file not found` so we pin it to a good commit for now
      inputs.nixpkgs.follows = "nixpkgs-patch";
    };
    determinatenix = {
      url = "https://flakehub.com/f/DeterminateSystems/nix/2.27.*";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    otel-tui = {
      url = "github:ymtdzzz/otel-tui/v0.4.3";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llm-functions = {
      url = "github:sigoden/llm-functions/main";
      flake = false;
    };
    zed-editor = {
      url = "github:HPsaucii/zed-editor-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, nix-vscode-extensions, attic
    , determinatenix, otel-tui, llm-functions, zed-editor, ... }:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          allowUnfreePredicate = _: true;
        };
        overlays = [ nix-vscode-extensions.overlays.default ];
      } // {
        attic = attic.packages.${system}.attic;
        nix = determinatenix.packages.${system}.default;
      };
    in {
      homeConfigurations."oftaylor" =
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;

          # Specify your home configuration modules here, for example,
          # the path to your home.nix.
          modules = [
            (import ./home.nix {
              inherit pkgs;
              importPath = ./personal;
              lib = home-manager.lib;
              llmFunctionsPath = llm-functions;
              inherit zed-editor;
            })
          ];

          # Optionally use extraSpecialArgs
          # to pass through arguments to home.nix
        };
      # TODO: Figure this out so I can pass some sort of variable called "work" and then do it that
      # way
      homeConfigurations."taylor" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        # Specify your home configuration modules here, for example,
        # the path to your home.nix.
        modules = [
          (import ./home.nix {
            inherit pkgs;
            importPath = ./work;
            lib = home-manager.lib;
            llmFunctionsPath = llm-functions;
            inherit zed-editor;
          })
        ];

        # Optionally use extraSpecialArgs
        # to pass through arguments to home.nix
        extraSpecialArgs = { otel-tui = otel-tui.packages.${system}.otel-tui; };
      };
    };
}
