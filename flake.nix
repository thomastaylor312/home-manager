{
  description = "Home Manager configuration";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    determinatenix = {
      url = "https://flakehub.com/f/DeterminateSystems/nix/2.27.*";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    otel-tui = {
      url = "github:ymtdzzz/otel-tui/v0.5.5";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llm-functions = {
      url = "github:sigoden/llm-functions/main";
      flake = false;
    };
  };

  outputs = { nixpkgs, home-manager, nix-vscode-extensions, determinatenix
    , otel-tui, llm-functions, ... }:
    let
      systems = [
        {
          slug = "darwin";
          system = "aarch64-darwin";
        }
        {
          slug = "linux";
          system = "x86_64-linux";
        }
      ];

      mkPkgs = system:
        let
          base = import nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
              allowUnfreePredicate = _: true;
            };
            overlays = [ nix-vscode-extensions.overlays.default ];
          };
          determinateOverride =
            if builtins.hasAttr system determinatenix.packages then
              let determinatePkgs = determinatenix.packages.${system}; in
              if determinatePkgs ? default then { nix = determinatePkgs.default; } else { }
            else
              { };
        in base // determinateOverride;

      mkOtelTui = system:
        if builtins.hasAttr system otel-tui.packages then
          let otelPackages = otel-tui.packages.${system}; in
          if otelPackages ? otel-tui then otelPackages.otel-tui else null
        else
          null;

      mkHomeEntry = { username, importPath, system, slug, needsOtelTui ? false, extraSpecialArgs ? { } }:
        let
          pkgs = mkPkgs system;
          otelArg =
            if needsOtelTui then
              let otelPackage = mkOtelTui system;
              in if otelPackage != null then { otel-tui = otelPackage; } else { }
            else
              { };
          finalSpecialArgs = otelArg // extraSpecialArgs;
        in {
          name = "${username}-${slug}";
          value = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [
              (import ./home.nix {
                inherit pkgs;
                importPath = importPath;
                lib = home-manager.lib;
                llmFunctionsPath = llm-functions;
              })
            ];
            extraSpecialArgs = finalSpecialArgs;
          };
        };

      homeEntries = builtins.concatMap (systemData:
        let inherit (systemData) system slug; in [
          (mkHomeEntry {
            username = "oftaylor";
            importPath = ./personal;
            inherit system slug;
          })
          (mkHomeEntry {
            username = "taylor";
            importPath = ./work;
            inherit system slug;
            needsOtelTui = true;
          })
        ]) systems;

      homes = builtins.listToAttrs homeEntries;
    in {
      homeConfigurations =
        homes // {
          oftaylor = homes."oftaylor-darwin";
          taylor = homes."taylor-darwin";
        };
    };
}
