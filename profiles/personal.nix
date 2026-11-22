{ pkgs, ... }:
{
  imports = [ ../modules/base.nix ];

  home.username = "oftaylor";

  home.packages = with pkgs; [
    rclone
    doctl
    tesseract
  ];

  agentSkills.media-library-organize = ../files/skills/media-library-organize;

  programs.git.settings = {
    user.email = "taylor@oftaylor.com";
    init.defaultBranch = "master";
  };

  # Only takes effect in configurations that include the GUI module.
  programs.vscode.profiles.default = {
    userSettings = {
      "svelte.enable-ts-plugin" = true;
      "git.enabled" = false;
    };
    extensions = with pkgs.vscode-extensions; [
      pkgs.vscode-marketplace.mtxr.sqltools
      bradlc.vscode-tailwindcss
      svelte.svelte-vscode
    ];
  };
}
