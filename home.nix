{ pkgs, importPath, lib, llmFunctionsPath, ... }:
let _packages = (import ./pkgs pkgs);
in {
  imports = [ importPath ];

  home.packages = with pkgs; [
    _1password-cli
    aichat
    aider-chat
    argc
    attic-client
    bat
    cachix
    claude-code
    cloc
    dasel
    delta
    docker
    ffmpeg
    gopls # For Go in helix
    hack-font
    iperf3
    jq
    just
    marksman
    mtr
    nil
    nixfmt-classic
    nmap
    nodejs_24
    openai-whisper
    protobuf
    rustup
    tailscale
    uv
    wget
    zig
    zls
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
      #"https://imperial-archives.dojo-nominal.ts.net/oftaylor"
      "https://wasmcloud.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "crane.cachix.org-1:8Scfpmn9w+hGdXH/Q9tTLiYAE/2dnJYRJP7kl80GuRk="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "oftaylor:vJMb7rKwt+U0EWs0atdKV7preTguDJQ/F4V4/z8VYJk="
      "wasmcloud.cachix.org-1:9gRBzsKh+x2HbVVspreFg/6iFRiD4aOcUQfXVDl3hiM="
    ];
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  programs.fd.enable = true;

  fonts.fontconfig.enable = true;

  programs.helix = {
    enable = true;
    defaultEditor = true;
    settings = {
      theme = "dracula";
      editor = { file-picker = { hidden = false; }; };
    };
    languages = {
      language = [{
        name = "nix";
        formatter = { command = "nixfmt"; };
        auto-format = true;
      }];
    };
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      custom = {
        jj = {
          ignore_timeout = true;
          description = "The current jj status";
          detect_folders = [ ".jj" ];
          symbol = "🥋 ";
          command = ''
            jj log --revisions @ --no-graph --ignore-working-copy --color always --limit 1 --template '
              separate(" ",
                change_id.shortest(4),
                bookmarks,
                "|",
                concat(
                  if(conflict, "💥"),
                  if(divergent, "🚧"),
                  if(hidden, "👻"),
                  if(immutable, "🔒"),
                ),
                raw_escape_sequence("\x1b[1;32m") ++ if(empty, "(empty)"),
                raw_escape_sequence("\x1b[1;32m") ++ coalesce(
                  truncate_end(29, description.first_line(), "…"),
                  "(no description set)",
                ) ++ raw_escape_sequence("\x1b[0m"),
              )
            '
          '';
        };
        # re-enable git_branch as long as we're not in a jj repo
        git_branch = {
          when = true;
          command =
            "jj root --ignore-working-copy >/dev/null 2>&1 || starship module git_branch";
          description = "Only show git_branch if we're not in a jj repo";
        };

        git_state = {
          when = true;
          command =
            "jj root --ignore-working-copy >/dev/null 2>&1 || starship module git_state";
          description = "Only show git_state if we're not in a jj repo";
        };

        git_commit = {
          when = true;
          command =
            "jj root --ignore-working-copy >/dev/null 2>&1 || starship module git_commit";
          description = "Only show git_commit if we're not in a jj repo";
        };

        git_metrics = {
          when = true;
          command =
            "jj root --ignore-working-copy >/dev/null 2>&1 || starship module git_metrics";
          description = "Only show git_metrics if we're not in a jj repo";
        };
      };
      git_state = { disabled = true; };

      git_commit = { disabled = true; };

      git_metrics = { disabled = true; };

      git_branch = { disabled = true; };
    };
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
      theme = "dracula"; # Sublette is another I like
      macos-icon = "glass";
    };
    themes = {
      dracula = {
        background = "282a36";
        cursor-color = "f8f8f2";
        cursor-text = "282a36";
        foreground = "f8f8f2";
        palette = [
          "0=#21222c"
          "1=#ff5555"
          "2=#50fa7b"
          "3=#f1fa8c"
          "4=#bd93f9"
          "5=#ff79c6"
          "6=#8be9fd"
          "7=#f8f8f2"
          "8=#6272a4"
          "9=#ff6e6e"
          "10=#69ff94"
          "11=#ffffa5"
          "12=#d6acff"
          "13=#ff92df"
          "14=#a4ffff"
          "15=#ffffff"
        ];
        selection-background = "44475a";
        selection-foreground = "f8f8f2";
      };

    };
  };

  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      sync_address = "http://imperial-archives.dojo-nominal.ts.net:9999";
      sync_frequency = "5m";
      enter_accept = true;
      store_failed = true;
    };
  };

  programs.zsh = {
    enable = true;

    initContent = ''
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
        "OPENROUTER_API_KEY=$(op read --account ZYK5R7INKFEFBMCZGVCN7TTLSQ 'op://Private/aider-openrouter-key/credential') aider --no-auto-commits --cache-prompts";
      cd = "z";
    };

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "jj" "1password" ];
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

  programs.jujutsu = {
    enable = true;
    settings = {
      user = { name = "Taylor Thomas"; };
      ui = {
        pager = "delta";
        diff-formatter = ":git";
        merge-editor = "vscode";
      };
      revsets = {
        log =
          "present(@) | ancestors(immutable_heads().., 8) | present(trunk())";
      };
      templates = { commit_trailers = "format_signed_off_by_trailer(self)"; };
      signing = {
        behavior = "own";
        backend = "gpg";
      };
    };
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
      pkgs.vscode-marketplace.jjk.jjk
      pkgs.vscode-marketplace.rooveterinaryinc.roo-cline
      dracula-theme.theme-dracula
    ];
    profiles.default = {
      userSettings = {
        "editor.inlineSuggest.enabled" = true;
        "workbench.colorTheme" = "Dracula Theme";
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
        "cody.suggestions.mode" = "auto-edit";
        "github.copilot.nextEditSuggestions.enabled" = true;
        "github.copilot.enable" = {
          "*" = true;
          "plaintext" = false;
          "markdown" = true;
          "scminput" = false;
        };
      };
      userMcp = {
        "inputs" = [{
          "type" = "promptString";
          "id" = "github_token";
          "description" = "GitHub Personal Access Token";
          "password" = true;
        }];
        "servers" = {
          "github" = {
            "command" = "docker";
            "args" = [
              "run"
              "-i"
              "--rm"
              "-e"
              "GITHUB_PERSONAL_ACCESS_TOKEN"
              "ghcr.io/github/github-mcp-server"
            ];
            "env" = {
              "GITHUB_PERSONAL_ACCESS_TOKEN" = "\${input:github_token}";
            };
          };
          fetch = {
            "command" = "docker";
            "args" = [ "run" "-i" "--rm" "mcp/fetch" ];
          };
        };
      };
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
        pushd $HOME/Library/Application\ Support/aichat/functions > /dev/null 2>&1 && argc mcp start 1>/dev/null && popd > /dev/null 2>&1 && command aichat "$@" < /dev/stdin
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
      model: openrouter:openai/o4-mini
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
            json_path="$HOME/Library/Application Support/Code/User/globalStorage/rooveterinaryinc.roo-cline/settings/mcp_settings.json"
            run rm -f "$json_path"
            run cat > "$json_path" << 'EOF'
      {
        "mcpServers": {
          "github": {
              "command": "docker",
              "args": [
                "run",
                "-i",
                "--rm",
                "-e",
                "GITHUB_PERSONAL_ACCESS_TOKEN",
                "ghcr.io/github/github-mcp-server"
              ],
              "env": {
                "GITHUB_PERSONAL_ACCESS_TOKEN": "<REPLACE_GH_TOKEN>"
              },
              "disabled": false,
              "autoApprove": []
          },
          "fetch": {
              "command": "docker",
              "args": [
                "run",
                "-i",
                "--rm",
                "mcp/fetch"
              ]
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
        export PATH="${pkgs.argc}/bin:${pkgs.nodejs_24}/bin:${pkgs.uv}/bin:${pkgs.docker}/bin:$PATH"

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
      json_file="$HOME/Library/Application Support/aichat/functions/mcp.json"
      run rm -f "$json_file"
      export PATH="${pkgs.argc}/bin:${pkgs.nodejs_24}/bin:${pkgs.uv}/bin:${pkgs.docker}/bin:$PATH"
      run cat > "$json_file" << 'EOF'
        {
          "mcpServers": {
            "github": {
              "command": "docker",
              "args": [
                "run",
                "-i",
                "--rm",
                "-e",
                "GITHUB_PERSONAL_ACCESS_TOKEN",
                "ghcr.io/github/github-mcp-server"
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
            },
            "fetch": {
                "command": "docker",
                "args": [
                  "run",
                  "-i",
                  "--rm",
                  "mcp/fetch"
                ]
            }
          }
        }
      EOF
      run ${pkgs._1password-cli}/bin/op read --account ZYK5R7INKFEFBMCZGVCN7TTLSQ "op://Private/mcp-github-token/credential" | run xargs -I{} sed -i"" 's/<REPLACE ME>/{}/g' "$json_file"
      run ${pkgs._1password-cli}/bin/op read --account ZYK5R7INKFEFBMCZGVCN7TTLSQ "op://Private/obsidian-rest-api/credential" | run xargs -I{} sed -i"" 's/<REPLACE ME2>/{}/g' "$json_file"
      run sed -i"" "s|<PATH>|$PATH|g" "$json_file"
      run chmod 400 "$json_file"

      # Run the wrapper script
      run ${buildScript}/bin/build-llm-functions
    '';
  };

  programs.zed-editor = {
    enable = true;
    extensions = [
      "cargo-tom"
      "docker-compose"
      "dockerfile"
      "dracula"
      "golangci-lint"
      "gosum"
      "make"
      "marksman"
      "nix"
      "one-dark-pro"
      "sql"
      "terraform"
      "toml"
      "wit"
    ];
    userSettings = {
      auto_update = false;
      show_edit_predictions = true;
      telemetry = { metrics = false; };
      features = { edit_prediction_provider = "copilot"; };
      preferred_line_length = 100;
      theme = {
        mode = "dark";
        dark = "Dracula";
        light = "Dracula";
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
      language_models = { copilot_chat = { }; };
      agent = {
        version = "2";
        enabled = true;
        default_model = {
          provider = "openrouter";
          model = "anthropic/claude-sonnet-4";
        };
        editor_model = {
          provider = "openrouter";
          model = "anthropic/claude-sonnet-4";
        };
      };
    };
  };
}
