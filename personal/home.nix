{ pkgs, ... }:
let packages = (pkgs // import ./pkgs pkgs);
in {
  config = rec {
    home.username = "oftaylor";
    home.homeDirectory = "/Users/${home.username}";

    nix.settings = {
      netrc-file = "/Users/${home.username}/.config/nix/netrc";
    };

    home.packages = [ packages.rclone packages.doctl ];

    programs.git = {
      userEmail = "taylor@oftaylor.com";
      userName = "Taylor Thomas";

      extraConfig = { init = { defaultBranch = "master"; }; };
    };

    programs.jujutsu = {
      settings = { user = { email = "taylor@oftaylor.com"; }; };
    };

    programs.zsh.shellAliases = {
      cache-home-manager =
        "nix build .#homeConfigurations.${home.username}.activationPackage --json | jq -r '.[].outputs | to_entries[].value' | attic push --stdin oftaylor";
    };

    programs.vscode = {
      profiles.default.userSettings = { "svelte.enable-ts-plugin" = true; };
      profiles.default.extensions = with packages.vscode-extensions; [
        ms-python.python
        ms-python.vscode-pylance
        ms-python.debugpy
        packages.vscode-marketplace.mtxr.sqltools
        bradlc.vscode-tailwindcss
        svelte.svelte-vscode
      ];
    };
  };
}
