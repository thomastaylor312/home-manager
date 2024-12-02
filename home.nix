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
      brewup = "brew update && brew upgrade && brew cleanup";
      vi = "hx";
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
