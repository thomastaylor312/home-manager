{ pkgs, ... }: {
  config = rec {
    home.username = "oftaylor";
    home.homeDirectory = "/Users/${home.username}";

    home.packages = [ pkgs.rclone pkgs.doctl ];

    programs.git = {
      userEmail = "taylor@oftaylor.com";
      userName = "Taylor Thomas";

      extraConfig = { init = { defaultBranch = "master"; }; };
    };
    programs.vscode = {
      extensions = with pkgs.vscode-extensions; [
        ms-python.python
        ms-python.vscode-pylance
        ms-python.debugpy
        sswg.swift-lang
        pkgs.vscode-marketplace.mtxr.sqltools
        bradlc.vscode-tailwindcss
      ];
    };
  };
}
