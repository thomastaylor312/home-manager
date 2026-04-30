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
    otel-tui = {
      url = "github:ymtdzzz/otel-tui/v0.5.5";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dracula-yazi = {
      url = "github:dracula/yazi/main";
      flake = false;
    };
    tuicr = {
      url = "github:agavra/tuicr/v0.10.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    helix = {
      url = "github:thomastaylor312/helix/inline-completion";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    obsidian-skills = {
      url = "github:kepano/obsidian-skills/main";
      flake = false;
    };
    age-plugin-1pass = {
      url = "github:thomastaylor312/age-plugin-1pass/v0.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    playwright-cli-src = {
      url = "github:microsoft/playwright-cli/v0.1.8";
      flake = false;
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      nix-vscode-extensions,
      otel-tui,
      dracula-yazi,
      tuicr,
      helix,
      obsidian-skills,
      age-plugin-1pass,
      playwright-cli-src,
      ...
    }:
    let
      systems = [
        {
          slug = "darwin";
          system = "aarch64-darwin";
          homeDirectoryBase = "/Users";
        }
        {
          slug = "linux";
          system = "x86_64-linux";
          homeDirectoryBase = "/home";
        }
      ];

      aiDevSystems = [
        {
          slug = "aarch64-linux";
          system = "aarch64-linux";
          homeDirectoryBase = "/home";
        }
        {
          slug = "x86_64-linux";
          system = "x86_64-linux";
          homeDirectoryBase = "/home";
        }
      ];

      mkPkgs =
        system:
        import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            allowUnfreePredicate = _: true;
          };
          overlays = [
            nix-vscode-extensions.overlays.default
            (_: prev: {
              direnv = prev.direnv.overrideAttrs (_: { doCheck = false; });
            })
          ];
        };

      mkOtelTui =
        system:
        if builtins.hasAttr system otel-tui.packages then
          let
            otelPackages = otel-tui.packages.${system};
          in
          if otelPackages ? otel-tui then otelPackages.otel-tui else null
        else
          null;

      mkHomeEntry =
        {
          username,
          importPath,
          system,
          slug,
          homeDirectoryBase,
          needsOtelTui ? false,
          extraSpecialArgs ? { },
        }:
        let
          pkgs = mkPkgs system;
          otelArg =
            if needsOtelTui then
              let
                otelPackage = mkOtelTui system;
              in
              if otelPackage != null then { otel-tui = otelPackage; } else { }
            else
              { };
          defaultSpecialArgs = {
            inherit homeDirectoryBase;
          }
          // otelArg;
          finalSpecialArgs = defaultSpecialArgs // extraSpecialArgs;
        in
        {
          name = "${username}-${slug}";
          value = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [ ./home.nix ];
            extraSpecialArgs = finalSpecialArgs // {
              inherit importPath;
              hmLib = home-manager.lib;
              draculaYaziPath = dracula-yazi;
              obsidianSkillsPath = obsidian-skills;
              tuicrPkg =
                if builtins.hasAttr system tuicr.defaultPackage then tuicr.defaultPackage.${system} else null;
              helixPkg =
                if builtins.hasAttr system helix.packages then helix.packages.${system}.default else null;
              agePlugin1passPkg =
                if builtins.hasAttr system age-plugin-1pass.packages then
                  age-plugin-1pass.packages.${system}.default
                else
                  null;
              playwrightCliSrc = playwright-cli-src;
            };
          };
        };

      mkAiDevEntry =
        {
          username,
          system,
          slug,
          homeDirectoryBase,
        }:
        let
          pkgs = mkPkgs system;
        in
        {
          name = "ai-dev-${slug}";
          value = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [ ./ai-dev.nix ];
            extraSpecialArgs = {
              inherit homeDirectoryBase username;
              hmLib = home-manager.lib;
              draculaYaziPath = dracula-yazi;
              playwrightCliSrc = playwright-cli-src;
            };
          };
        };

      homeEntries = builtins.concatMap (
        systemData:
        let
          inherit (systemData) system slug homeDirectoryBase;
        in
        [
          (mkHomeEntry {
            username = "oftaylor";
            importPath = ./personal;
            inherit system slug homeDirectoryBase;
          })
          (mkHomeEntry {
            username = "taylor";
            importPath = ./work;
            inherit system slug homeDirectoryBase;
            needsOtelTui = true;
          })
        ]
      ) systems;

      aiDevEntries = map (
        systemData:
        mkAiDevEntry {
          username = "taylor";
          inherit (systemData) system slug homeDirectoryBase;
        }
      ) aiDevSystems;

      homes = builtins.listToAttrs homeEntries;
      aiDevHomes = builtins.listToAttrs aiDevEntries;
    in
    {
      homeConfigurations =
        homes
        // aiDevHomes
        // {
          oftaylor = homes."oftaylor-darwin";
          taylor = homes."taylor-darwin";
        };
    };
}
