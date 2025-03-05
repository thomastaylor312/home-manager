{ pkgs, importPath, lib, ... }:

{
  imports = [ importPath ];

  home.packages = [
    pkgs.bat
    pkgs.cloc
    pkgs.mtr
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
    pkgs.uv
    pkgs.docker
    pkgs.nodejs_22
    pkgs.aichat
    pkgs.argc
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
      "https://cache.nixos.org"
      "https://crane.cachix.org"
      "https://nix-community.cachix.org"
      "https://imperial-archives.dojo-nominal.ts.net/oftaylor"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "crane.cachix.org-1:8Scfpmn9w+hGdXH/Q9tTLiYAE/2dnJYRJP7kl80GuRk="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "oftaylor:/F+43JMUT9r7G5lKdvvIDoF+KBNdGR6ZWevakY0BjZo="
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

  programs.ripgrep = {
    enable = true;
    arguments = [ "--hidden" ];
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
    profiles.default.extensions = with pkgs.vscode-extensions; [
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
      pkgs.vscode-marketplace.saoudrizwan.claude-dev
    ];
    profiles.default.userSettings = {
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
      "cody.suggestions.mode" = "auto-edit (Experimental)";
    };
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  home.file = {
    "Library/Application Support/aichat/functions" = {
      source = pkgs.fetchFromGitHub {
        owner = "sigoden";
        repo = "llm-functions";
        rev = "main";
        sha256 = "sha256-4Gmuu32m0NrjtgejH8bdh6t2KQ5/gwnAT7Eg8/1nhk4=";
      };
      recursive = true;
    };
    "Library/Application Support/aichat/functions/tools.txt".text = ''
      execute_command.sh
      fs_cat.sh
      fs_ls.sh
      fs_mkdir.sh
      fs_patch.sh
      fs_rm.sh
      fs_write.sh
      get_current_time.sh
      get_current_weather.sh
      search_arxiv.sh
      search_wikipedia.sh
    '';
    "Library/Application Support/aichat/functions/agents.txt".text = ''
      coder
    '';
  };

  # Setup aichat configuration with 1Password integration
  home.activation = {
    setupAichatConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            $DRY_RUN_CMD mkdir -p "$HOME/Library/Application Support/aichat"
            $DRY_RUN_CMD cat > "$HOME/Library/Application Support/aichat/config.yaml" << 'EOF'
      model: openrouter:openai/gpt-4o
      function_calling: true
      clients:
      - type: openai-compatible
        name: openrouter
        api_base: https://openrouter.ai/api/v1
        api_key: <REPLACE ME>
      EOF
            # On macOS, sed -i requires an extension argument but we need to avoid escaping issues
            $DRY_RUN_CMD ${pkgs._1password-cli}/bin/op read --account ZYK5R7INKFEFBMCZGVCN7TTLSQ "op://Private/aichat-openrouter-token/credential" | $DRY_RUN_CMD xargs -I{} sed -i"" 's/<REPLACE ME>/{}/g' "$HOME/Library/Application Support/aichat/config.yaml"
    '';

    setupClineMcp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            $DRY_RUN_CMD mkdir -p "$HOME/Library/Application Support/Code/User/globalStorage/saoudrizwan.claude-dev/settings"
            $DRY_RUN_CMD cat > "$HOME/Library/Application Support/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json" << 'EOF'
      {
        "mcpServers": {
          "github.com/modelcontextprotocol/servers/tree/main/src/github": {
            "command": "npx",
            "args": [
              "-y",
              "@modelcontextprotocol/server-github"
            ],
            "env": {
              "GITHUB_PERSONAL_ACCESS_TOKEN": "<REPLACE ME>"
            },
            "disabled": false,
            "autoApprove": []
          }
        }
      }
      EOF
      $DRY_RUN_CMD ${pkgs._1password-cli}/bin/op read --account ZYK5R7INKFEFBMCZGVCN7TTLSQ "op://Private/mcp-github-token/credential" | $DRY_RUN_CMD xargs -I{} sed -i"" 's/<REPLACE ME>/{}/g' "$HOME/Library/Application Support/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json"
    '';

    # Setup llm-functions for aichat
    setupLlmFunctions = let
      # Create a wrapper script that sets up the PATH correctly
      buildScript = pkgs.writeShellScriptBin "build-llm-functions" ''
        #!/usr/bin/env bash
        export PATH="${pkgs.argc}/bin:${pkgs.nodejs_22}/bin:${pkgs.uv}/bin:$PATH"
        cd "$HOME/Library/Application Support/aichat/functions"
        argc build
        argc check
      '';
    in lib.hm.dag.entryAfter [ "writeBoundary" "installPackages" ] ''
      # Run the wrapper script
      $DRY_RUN_CMD ${buildScript}/bin/build-llm-functions
    '';
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
