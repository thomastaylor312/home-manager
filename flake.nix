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
    dracula-yazi = {
      url = "github:dracula/yazi/main";
      flake = false;
    };
    helix = {
      url = "github:thomastaylor312/helix/inline-completion";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    obsidian-skills = {
      url = "github:obsidianmd/obsidian-skills/main";
      flake = false;
    };
    age-plugin-1pass = {
      url = "github:thomastaylor312/age-plugin-1pass/v0.1.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    playwright-cli-src = {
      url = "github:microsoft/playwright-cli/v0.1.8";
      flake = false;
    };
    omp = {
      url = "github:can1357/oh-my-pi";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ nixpkgs, home-manager, ... }:
    let
      mkHome =
        { system, modules }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
            overlays = [ inputs.nix-vscode-extensions.overlays.default ];
          };
          # Modules reach the other flake inputs (packages, themes, skills) through this.
          extraSpecialArgs = { inherit inputs; };
          inherit modules;
        };
    in
    {
      # Selected with `home-manager switch --flake .#<name>`. A name is only a label: the profile
      # module decides the username, and the home directory follows from that and the system.
      homeConfigurations = builtins.mapAttrs (_: mkHome) {
        personal-darwin = {
          system = "aarch64-darwin";
          modules = [
            ./profiles/personal.nix
            ./modules/gui.nix
          ];
        };
        personal-linux = {
          system = "x86_64-linux";
          modules = [
            ./profiles/personal.nix
            ./modules/gui.nix
          ];
        };
        personal-linux-headless = {
          system = "x86_64-linux";
          modules = [ ./profiles/personal.nix ];
        };
        work-darwin = {
          system = "aarch64-darwin";
          modules = [
            ./profiles/work.nix
            ./modules/gui.nix
          ];
        };
      };
    };
}
