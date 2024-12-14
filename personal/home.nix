{ pkgs, ... }:
let packages = (pkgs // import ./pkgs pkgs);
in {
  config = rec {
    home.username = "oftaylor";
    home.homeDirectory = "/Users/${home.username}";

    home.packages = [ packages.rclone packages.doctl ];

    programs.git = {
      userEmail = "taylor@oftaylor.com";
      userName = "Taylor Thomas";

      extraConfig = { init = { defaultBranch = "master"; }; };
    };

    programs.vscode = {
      extensions = with packages.vscode-extensions; [
        ms-python.python
        ms-python.vscode-pylance
        ms-python.debugpy
        sswg.swift-lang
        packages.vscode-marketplace.mtxr.sqltools
        bradlc.vscode-tailwindcss
      ];
    };
  };
}
