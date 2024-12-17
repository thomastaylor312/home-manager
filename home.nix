{ pkgs, importPath, ... }:

{
  imports = [ importPath ];

  home.packages = [
    pkgs.bat
    pkgs.cloc
    pkgs.mtr
    pkgs.ripgrep
    pkgs.iperf3
    pkgs.delta
    pkgs.wget
    pkgs.nmap
    pkgs.zig
    pkgs._1password-cli
    pkgs.nixfmt-classic
    pkgs.nil
    pkgs.rustup
    pkgs.tailscale
    pkgs.jq
    pkgs.attic
    pkgs.just
    pkgs.cachix
  ];

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "24.05";

  nix.package = pkgs.nix;
  nix.settings = {
    substituters = [
      "https://imperial-archives.dojo-nominal.ts.net/oftaylor"
      "https://cache.nixos.org"
      "ssh://eu.nixbuild.net"
      "https://crane.cachix.org"
    ];
    trusted-public-keys = [
      "oftaylor:/F+43JMUT9r7G5lKdvvIDoF+KBNdGR6ZWevakY0BjZo="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nixbuild.net/XZJQX6-1:hWCLZuADr7SgY3NwS2kMPHcnjAgYtRSFDh8O0Qm4nko="
      "crane.cachix.org-1:8Scfpmn9w+hGdXH/Q9tTLiYAE/2dnJYRJP7kl80GuRk="
    ];
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.helix = {
    enable = true;
    defaultEditor = true;
    settings.theme = "onedark";
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zsh = {
    enable = true;
    envExtra = ''
      . "$HOME/.cargo/env"
    '';
    sessionVariables = { MANPAGER = "sh -c 'col -bx | bat -l man -p'"; };

    shellAliases = {
      tree = "eza --tree";
      cat = "bat";
      vi = "hx";
      cache-build =
        "nix build --json | jq -r '.[].outputs | to_entries[].value' | attic push --stdin oftaylor";
      cache-inputs =
        "nix flake archive --json | jq -r '.path,(.inputs|to_entries[].value.path)' | attic push --stdin oftaylor";
      cache-all = "cache-build && cache-inputs";
    };

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
    };
  };

  programs.git = {
    enable = true;
    delta = {
      enable = true;
      options = {
        navigate = true;
        dark = true;
        hyperlinks = true;
      };
    };
    userName = "Taylor Thomas";
    extraConfig = {
      merge = { conflictstyle = "zdiff3"; };
      core = { blame = "delta"; };
    };
    ignores = [
      ".direnv/"
    ];
  };

  programs.gh = {
    enable = true;
    settings = { git_protocol = "ssh"; };
  };

  programs.gh-dash.enable = true;

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    config.global.load_dotenv = true;
    nix-direnv.enable = true;
  };

  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    colors = "auto";
  };

  programs.vscode = {
    enable = true;
    extensions = with pkgs.vscode-extensions; [
      vadimcn.vscode-lldb
      pkgs.vscode-marketplace.sourcegraph.cody-ai
      fill-labs.dependi
      mkhl.direnv
      tamasfe.even-better-toml
      ms-vsliveshare.vsliveshare
      yzhang.markdown-all-in-one
      jnoortheen.nix-ide
      zhuangtongfa.material-theme
      stkb.rewrap
      rust-lang.rust-analyzer
      golang.go
    ];
    userSettings = {
      "editor.inlineSuggest.enabled" = true;
      "workbench.colorTheme" = "One Dark Pro";
      "editor.formatOnSave" = true;
      "rust-analyzer.check.command" = "clippy";
      "rewrap.wrappingColumn" = 100;
      "editor.wordWrap" = "on";
      "explorer.confirmDelete" = false;
      "editor.inlineSuggest.suppressSuggestions" = true;
      "cody.commandCodeLenses" = true;
      "update.showReleaseNotes" = false;
      "zig.path" = "zig";
      "lldb.library" =
        "/Library/Developer/CommandLineTools/Library/PrivateFrameworks/LLDB.framework/Versions/A/LLDB";
      "lldb.launch.expressions" = "native";
      "swift.backgroundCompilation" = true;
      "nix.enableLanguageServer" = true;
      "nix.serverPath" = "nil";
      "nix.serverSettings" = {
        "nil" = { "formatting" = { "command" = [ "nixfmt" ]; }; };
      };
    };
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  # I might just move this to work
  programs.zed-editor = {
    enable = true;
    extensions = [ "nix" "golangci-lint" "gosum" ];
    userSettings = { telemetry = { metrics = false; }; };
  };
}
