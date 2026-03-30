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
    dracula-yazi = {
      url = "github:dracula/yazi/main";
      flake = false;
    };
    beads = {
      # Current flake has a hash mismatch so pinning to a known good commit
      url = "github:steveyegge/beads/f320e3cc13519259d4586e8fa26dcdfb0665e1a2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    tuicr = {
      url = "github:agavra/tuicr/v0.8.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    helix = {
      url = "github:thomastaylor312/helix/inline-completion";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      nix-vscode-extensions,
      determinatenix,
      otel-tui,
      dracula-yazi,
      beads,
      tuicr,
      helix,
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
              let
                determinatePkgs = determinatenix.packages.${system};
              in
              if determinatePkgs ? default then
                {
                  nix = determinatePkgs.default;
                }
              else
                { }
            else
              { };
          beadsOverride =
            if builtins.hasAttr system beads.packages then
              let
                beadsPackages = beads.packages.${system};
              in
              if beadsPackages ? default then
                {
                  "beads-repo" = beadsPackages.default;
                }
              else
                { }
            else
              { };
        in
        base // determinateOverride // beadsOverride;

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
              beadsRepo =
                if builtins.hasAttr system beads.packages then beads.packages.${system}.default else null;
              tuicrPkg =
                if builtins.hasAttr system tuicr.defaultPackage then tuicr.defaultPackage.${system} else null;
              helixPkg =
                if builtins.hasAttr system helix.packages then helix.packages.${system}.default else null;
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
      homeConfigurations = homes // aiDevHomes // {
        oftaylor = homes."oftaylor-darwin";
        taylor = homes."taylor-darwin";
      };
    };
}
