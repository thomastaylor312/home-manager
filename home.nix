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
    pkgs.hack-font
    pkgs.zls
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
    substituters = [ "https://cache.nixos.org" "https://crane.cachix.org" ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "crane.cachix.org-1:8Scfpmn9w+hGdXH/Q9tTLiYAE/2dnJYRJP7kl80GuRk="
    ];
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  fonts.fontconfig.enable = true;

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
    ignores = [ ".direnv/" ];
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
      #vadimcn.vscode-lldb
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
      ziglang.vscode-zig
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
      "zig.zls.enabled" = "on";
      "zig.zls.path" = "zls";
      "lldb.library" =
        "/Library/Developer/CommandLineTools/Library/PrivateFrameworks/LLDB.framework/Versions/A/LLDB";
      "lldb.launch.expressions" = "native";
      "swift.backgroundCompilation" = true;
      "nix.enableLanguageServer" = true;
      "nix.serverPath" = "nil";
      "nix.serverSettings" = {
        "nil" = { "formatting" = { "command" = [ "nixfmt" ]; }; };
      };
      "go.toolsManagement.autoUpdate" = true;
    };
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  # I might just move this to work
  programs.zed-editor = {
    enable = true;
    extensions =
      [ "nix" "golangci-lint" "gosum" "one-dark-pro" "cargo-tom" "toml" "wit" ];
    userSettings = {
      telemetry = { metrics = false; };
      features = { inline_completion_provider = "copilot"; };
      theme = {
        mode = "dark";
        dark = "One Dark Pro";
        light = "One Dark Pro";
      };
      languages = { Nix = { language_servers = [ "nil" "!nixd" ]; }; };
      lsp = {
        nil = { settings = { formatting = { command = [ "nixfmt" ]; }; }; };
        rust-analyzer = {
          initialization_options = { check = { command = "clippy"; }; };
        };
      };
      buffer_font_features = { calt = false; };
      buffer_font_family = "Hack";
      assistant = {
        version = "2";
        default_model = { provider = "copilot"; };
      };
    };
  };
}
