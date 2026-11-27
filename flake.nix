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
    # Prebuilt releases rather than the source repo: building means fetching a patched Electron and
    # compiling a Rust engine and a Swift helper. Update by bumping the version in both URLs (the
    # current one is listed at https://terminal-browser.sh/install/latest.json); the package reads
    # its version from here.
    #
    # Fetched as plain files, not tarballs: Nix's unpacker turns the macOS archive's metadata into
    # stray `._*` files inside the signed app bundle, and macOS then refuses to launch it as
    # damaged. pkgs/terminal-browser.nix unpacks them without those.
    terminal-browser-darwin-arm64 = {
      url = "file+https://terminal-browser.sh/install/dl/stable/v0.16.3/terminal-browser-darwin-arm64.tar.gz";
      flake = false;
    };
    terminal-browser-linux-x64 = {
      url = "file+https://terminal-browser.sh/install/dl/stable/v0.16.3/terminal-browser-linux-x64.tar.gz";
      flake = false;
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
