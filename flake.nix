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
      url = "github:steveyegge/beads/v0.49.0";
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

      homes = builtins.listToAttrs homeEntries;
    in
    {
      homeConfigurations = homes // {
        oftaylor = homes."oftaylor-darwin";
        taylor = homes."taylor-darwin";
      };
    };
}
