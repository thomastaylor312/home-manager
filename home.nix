{ pkgs, importPath, lib, llmFunctionsPath, ... }:

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
    pkgs.protobuf
    pkgs.claude-code
    pkgs.aider-chat
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
  programs.fd.enable = true;

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

  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    settings = { manager = { show_hidden = true; }; };
  };

  programs.ghostty = {
    enable = true;
    enableZshIntegration = true;
    package = null;
    settings = {
      window-save-state = "always";
      font-family = "Hack";
      window-padding-x = 15;
      window-padding-y = 15;
      window-padding-balance = true;
      theme = "GruvboxDarkHard"; # Sublette is another I like
    };
  };

  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      sync_address = "http://imperial-archives.dojo-nominal.ts.net:9999";
      sync_frequency = "5m";
    };
  };

  programs.zsh = {
    enable = true;
    envExtra = ''
      . "$HOME/.cargo/env"
    '';

    initExtra = ''
      source $HOME/.config/zsh/aichat-integration.zsh
    '';

    autosuggestion.enable = true;

    shellAliases = {
      tree = "eza --tree";
      cat = "bat";
      vi = "hx";
      cache-build =
        "nix build --json | jq -r '.[].outputs | to_entries[].value' | attic push --stdin oftaylor";
      cache-inputs =
        "nix flake archive --json | jq -r '.path,(.inputs|to_entries[].value.path)' | attic push --stdin oftaylor";
      cache-all = "cache-build && cache-inputs";
      aichat = "$HOME/aichat.sh";
      aider =
        "OPENROUTER_API_KEY=$(op read --account ZYK5R7INKFEFBMCZGVCN7TTLSQ 'op://Private/aider-openrouter-key/credential') aider --no-auto-commits";
      cd = "z";
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
    ignores = [ ".direnv/" ".aider*" ];
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

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
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
      pkgs.vscode-marketplace.rooveterinaryinc.roo-cline
      pkgs.vscode-marketplace-release.eamodio.gitlens
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
    ".config/zsh/aichat-integration.zsh" = {
      source = ./files/aichat-zsh-integration.zsh;
      executable = true;
    };
    "Library/Application Support/aichat/functions" = {
      source = llmFunctionsPath;
      recursive = true;
      force = true;
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
    "aichat.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        pushd $HOME/Library/Application\ Support/aichat/functions && argc mcp start 1> /dev/null && popd && command aichat "$@" < /dev/stdin
      '';
    };
  };

  # Setup aichat configuration with 1Password integration
  home.activation = {
    setupAichatConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            run mkdir -p "$HOME/Library/Application Support/aichat"
            yaml_path="$HOME/Library/Application Support/aichat/config.yaml"
            run rm -f "$yaml_path"
            run cat > "$yaml_path" << 'EOF'
      model: openrouter:openai/gpt-4o
      function_calling: true
      rag_embedding_model: ollama:nomic-embed-text
      clients:
      - type: openai-compatible
        name: openrouter
        api_base: https://openrouter.ai/api/v1
        api_key: <REPLACE ME>
      - type: openai-compatible
        name: ollama
        api_base: http://localhost:11434/v1
        models:
        - name: nomic-embed-text
          type: embedding
        - name: phi4:14b-q8_0
          max_input_tokens: 16000
      EOF
            # On macOS, sed -i requires an extension argument but we need to avoid escaping issues
            run ${pkgs._1password-cli}/bin/op read --account ZYK5R7INKFEFBMCZGVCN7TTLSQ "op://Private/aichat-openrouter-token/credential" | run xargs -I{} sed -i"" 's/<REPLACE ME>/{}/g' "$yaml_path"
            run chmod 400 "$yaml_path"
    '';

    setupClineMcp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            run mkdir -p "$HOME/Library/Application Support/Code/User/globalStorage/rooveterinaryinc.roo-cline/settings"
            json_path="$HOME/Library/Application Support/Code/User/globalStorage/rooveterinaryinc.roo-cline/settings/cline_mcp_settings.json"
            run rm -f "$json_path"
            run cat > "$json_path" << 'EOF'
      {
        "mcpServers": {
          "github": {
            "command": "npx",
            "args": [
              "-y",
              "@modelcontextprotocol/server-github"
            ],
            "env": {
              "GITHUB_PERSONAL_ACCESS_TOKEN": "<REPLACE_GH_TOKEN>"
            },
            "disabled": false,
            "autoApprove": []
          }
        }
      }
      EOF
      run ${pkgs._1password-cli}/bin/op read --account ZYK5R7INKFEFBMCZGVCN7TTLSQ "op://Private/mcp-github-token/credential" | run xargs -I{} sed -i"" 's/<REPLACE_GH_TOKEN>/{}/g' "$json_path"
      run chmod 400 "$json_path"
    '';

    # Setup llm-functions for aichat
    setupLlmFunctions = let
      # Create a wrapper script that sets up the PATH correctly
      buildScript = pkgs.writeShellScriptBin "build-llm-functions" ''
        #!/usr/bin/env bash
        export PATH="${pkgs.argc}/bin:${pkgs.nodejs_22}/bin:${pkgs.uv}/bin:$PATH"

        FUNCTIONS_DIR="$HOME/Library/Application Support/aichat/functions"

        # First, let's make actual copies of the symlinked files
        echo "Creating real copies of symlinked files..."
        cd "$FUNCTIONS_DIR/mcp/bridge"

        # Replace symlinks with actual copies. This funky thing is to avoid issues with finding the
        # installed packages because the file exists in nix
        for file in index.js package.json README.md; do
          if [ -L "$file" ]; then
            # Get the target of the symlink
            target=$(readlink "$file")
            # Remove the symlink
            rm "$file"
            # Copy the actual file
            cp "$target" "$file"
          fi
        done

        # Now we can run npm install
        npm install

        # Return to the main directory and continue with build
        cd "$FUNCTIONS_DIR"
        argc build
        argc check
      '';
    in lib.hm.dag.entryAfter [ "writeBoundary" "installPackages" ] ''
      # Run the wrapper script
      json_file="$HOME/Library/Application Support/aichat/functions/mcp.json"
      run rm -f "$json_file"
      export PATH="${pkgs.argc}/bin:${pkgs.nodejs_22}/bin:${pkgs.uv}/bin:$PATH"
      run cat > "$json_file" << 'EOF'
        {
          "mcpServers": {
            "github": {
              "command": "npx",
              "args": [
                "-y",
                "@modelcontextprotocol/server-github"
              ],
              "env": {
                "GITHUB_PERSONAL_ACCESS_TOKEN": "<REPLACE ME>",
                "PATH": "<PATH>"
              },
              "disabled": false,
              "autoApprove": []
            },
            "obsidian": {
              "command": "uvx",
              "args": [
                "mcp-obsidian"
              ],
              "env": {
                "OBSIDIAN_API_KEY":"<REPLACE ME2>",
                "PATH": "<PATH>"
              }
            }
          }
        }
      EOF
      run ${pkgs._1password-cli}/bin/op read --account ZYK5R7INKFEFBMCZGVCN7TTLSQ "op://Private/mcp-github-token/credential" | run xargs -I{} sed -i"" 's/<REPLACE ME>/{}/g' "$json_file"
      run ${pkgs._1password-cli}/bin/op read --account ZYK5R7INKFEFBMCZGVCN7TTLSQ "op://Private/obsidian-rest-api/credential" | run xargs -I{} sed -i"" 's/<REPLACE ME2>/{}/g' "$json_file"
      run sed -i"" "s|<PATH>|$PATH|g" "$json_file"
      run chmod 400 "$json_file"

      run ${buildScript}/bin/build-llm-functions
    '';
  };

  programs.zed-editor = {
    enable = true;
    extensions =
      [ "nix" "golangci-lint" "gosum" "one-dark-pro" "cargo-tom" "toml" "wit" ];
    userSettings = {
      auto_update = false;
      telemetry = { metrics = false; };
      features = { edit_prediction_provider = "copilot"; };
      preferred_line_length = 100;
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
      language_models = {
        copilot_chat = { };
        anthropic = {
          version = 1;
          api_url = "https://api.anthropic.com";
        };
      };
      assistant = {
        version = "2";
        enabled = true;
        default_model = {
          provider = "anthropic";
          model = "claude-3-7-sonnet-latest";
        };
        editor_model = {
          provider = "anthropic";
          model = "claude-3-7-sonnet-latest";
        };
      };
    };
  };
}
