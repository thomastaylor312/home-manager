args@{
  config,
  pkgs,
  draculaYaziPath,
  playwrightCliSrc,
  ...
}:
let
  nixpkgsLib = args.lib;
  hmLib = args.hmLib;
  lib = nixpkgsLib // hmLib;

  playwright-cli = pkgs.buildNpmPackage {
    pname = "playwright-cli";
    version = "0.1.8";
    src = playwrightCliSrc;

    npmDepsHash = "sha256-DK+nTRdVKznerAMK7McCCgr2OK4GXymbmgyR9qU/aH4=";

    dontNpmBuild = true;

    env = {
      PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";
      PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true";
    };

    nativeBuildInputs = [ pkgs.makeWrapper ];

    postInstall = ''
      wrapProgram $out/bin/playwright-cli \
        --set PLAYWRIGHT_BROWSERS_PATH ${pkgs.playwright-driver.browsers} \
        --set PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS true
    '';

    meta = {
      description = "CLI for common Playwright actions";
      homepage = "https://github.com/microsoft/playwright-cli";
      license = lib.licenses.asl20;
      mainProgram = "playwright-cli";
    };
  };
in
{
  home.packages =
    with pkgs;
    let
      base = [
        age
        bat
        cachix
        cloc
        delta
        ffmpeg
        hack-font
        hexyl
        imagemagick
        jjui
        jq
        just
        nil
        nixfmt
        nodejs_24
        playwright-cli
        protobuf
        python314
        scooter
        tailscale
        uv
        wget
        zig
        zls
        # Language servers for helix
        copilot-language-server
        bash-language-server
        gopls
        gotools
        harper
        marksman
        taplo
        terraform-ls
        typescript-language-server
        vscode-json-languageserver
        yaml-language-server
      ];
      macOnly = lib.optionals stdenv.isDarwin [ _1password-cli ];
    in
    base ++ macOnly;

  home.file = {
    ".claude/CLAUDE.md" = {
      source = ./files/GLOBAL_AGENTS.md;
    };
    ".claude/agents/code-review.md" = {
      source = ./files/agents/claude-code-review.md;
    };
    ".claude/skills/gh-notifications-triage" = {
      source = ./files/skills/gh-notifications-triage;
    };
    ".codex/AGENTS.md" = {
      source = ./files/GLOBAL_AGENTS.md;
    };
    # This might not work because it references claude specific tools, but figured I might as well
    # try it out
    ".codex/prompts/code-review.md" = {
      source = ./files/agents/claude-code-review.md;
    };
    ".codex/skills/gh-notifications-triage" = {
      source = ./files/skills/gh-notifications-triage;
    };
  };

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "26.05";

  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.cargo/bin"
  ];

  nix.package = pkgs.nix;
  nix.settings = {
    substituters = [
      "https://cache.nixos.org"
      "https://crane.cachix.org"
      "https://nix-community.cachix.org"
      "https://thomastaylor312.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "crane.cachix.org-1:8Scfpmn9w+hGdXH/Q9tTLiYAE/2dnJYRJP7kl80GuRk="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "thomastaylor312.cachix.org-1:Sw6GQLZQQ7TZfVud4VqH7pXNp/4N2NLdz30CfQjK5ZM="
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
      editor = {
        file-picker = {
          hidden = false;
        };
        soft-wrap = {
          enable = true;
        };
        inline-diagnostics = {
          cursor-line = "hint";
          other-lines = "error";
        };
        lsp.display-inlay-hints = true;
      };
      keys = {
        # NOTE: these won't actually work until ghostty can properly pass through these rather than
        # intercepting them when in TUI mode for things like helix
        insert = {
          "A-j" = "move_prev_word_start";
          "A-l" = "move_next_word_start";
          "A-backspace" = "delete_word_backward";
          "Cmd-l" = "goto_line_end";
          "Cmd-j" = "goto_line_start";
          "Cmd-i" = "goto_file_start";
          "Cmd-k" = "goto_file_end";
        };
        normal = {
          "C-d" = [
            "move_prev_word_start"
            "move_next_word_end"
            "search_selection"
            "extend_search_next"
          ];
          "Cmd-s" = ":write";
          "Cmd-r" = ":reload-all";
          "Cmd-c" = "yank_to_clipboard";
          "Cmd-f" = "search";
          "Cmd-x" = ''@"+d'';
          "p" = "paste_before";
          "C-t" = ":vsplit-new";
          "C-n" = ":new";
          "C-b" = ":echo %sh{git blame -L %{cursor_line},+1 %{buffer_name}}";
          "A-down" = [
            "extend_to_line_bounds"
            "delete_selection"
            "paste_after"
          ];
          "A-up" = [
            "extend_to_line_bounds"
            "delete_selection"
            "move_line_up"
            "paste_before"
          ];
          "space" = {
            # Copies the directory containing the current file (for use in go tests and other commands)
            "=" = ":sh echo %{buffer_name} | xargs dirname | pbcopy";
          };
          "C-r" = [
            ":write-all"
            ":insert-output scooter --no-stdin >/dev/tty"
            ":redraw"
            ":reload-all"
            ":set mouse false"
            ":set mouse true"
          ];
        };
      };
    };
    languages = {
      language = [
        {
          name = "nix";
          formatter = {
            command = "nixfmt";
          };
          auto-format = true;
          language-servers = [
            "nil"
            "copilot"
          ];
        }
        {
          name = "rust";
          language-servers = [
            "rust-analyzer"
            "copilot"
          ];
        }
        {
          name = "bash";
          language-servers = [
            "bash-language-server"
            "copilot"
          ];
        }
        {
          name = "docker-compose";
          language-servers = [
            "yaml-language-server"
            "copilot"
          ];
        }
        {
          name = "go";
          language-servers = [
            "gopls"
            "copilot"
          ];
          formatter.command = "goimports";
        }
        {
          name = "hcl";
          language-servers = [
            "terraform-ls"
            "copilot"
          ];
        }
        {
          name = "javascript";
          language-servers = [
            "typescript-language-server"
            "copilot"
          ];
        }
        {
          name = "jsx";
          language-servers = [
            "typescript-language-server"
            "copilot"
          ];
        }
        {
          name = "typescript";
          language-servers = [
            "typescript-language-server"
            "copilot"
          ];
        }
        {
          name = "zig";
          language-servers = [
            "zls"
            "copilot"
          ];
        }
        {
          name = "markdown";
          language-servers = [
            "marksman"
            "harper"
            "copilot"
          ];
        }
        {
          name = "yaml";
          language-servers = [
            "yaml-language-server"
            "copilot"
          ];
          indent = {
            tab-width = 2;
            unit = " ";
          };
        }
      ];
      language-server = {
        copilot = {
          command = "copilot-language-server";
          args = [ "--stdio" ];
          config = {
            editorInfo = {
              name = "helix";
              version = "25.07.1";
            };
            editorPluginInfo = {
              name = "helix-copilot";
              version = "0.1.0";
            };
          };
        };
        rust-analyzer.config = {
          check.command = "clippy";
        };
        yaml-language-server = {
          config.yaml = {
            completion = true;
            format.enable = true;
            schemas = {
              kubernetes = "/*.{yml,yaml}";
              "https://www.schemastore.org/github-workflow" = ".github/workflows/*";
              "https://www.schemastore.org/github-action" = ".github/action.{yml,yaml}";
              "https://www.schemastore.org/kustomization" = "kustomization.{yml,yaml}";
              "https://www.schemastore.org/chart" = "Chart.{yml,yaml}";
              "https://www.schemastore.org/dependabot-v2" = ".github/dependabot.{yml,yaml}";
              "https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json" =
                "*docker-compose*.{yml,yaml}";
            };
            hover = true;
          };
        };
        harper = {
          command = "harper-ls";
          args = [ "--stdio" ];
        };
      };
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
          command = "jj root --ignore-working-copy >/dev/null 2>&1 || starship module git_branch";
          description = "Only show git_branch if we're not in a jj repo";
        };

        git_state = {
          when = true;
          command = "jj root --ignore-working-copy >/dev/null 2>&1 || starship module git_state";
          description = "Only show git_state if we're not in a jj repo";
        };

        git_commit = {
          when = true;
          command = "jj root --ignore-working-copy >/dev/null 2>&1 || starship module git_commit";
          description = "Only show git_commit if we're not in a jj repo";
        };

        git_metrics = {
          when = true;
          command = "jj root --ignore-working-copy >/dev/null 2>&1 || starship module git_metrics";
          description = "Only show git_metrics if we're not in a jj repo";
        };
      };
      git_state = {
        disabled = true;
      };

      git_commit = {
        disabled = true;
      };

      git_metrics = {
        disabled = true;
      };

      git_branch = {
        disabled = true;
      };
    };
  };

  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      mgr = {
        show_hidden = true;
      };
      tasks.image_bound = [
        10000
        10000
      ];
    };
    theme = {
      dark.flavor = "dracula";
    };
    flavors = {
      dracula = draculaYaziPath;
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

    autosuggestion.enable = true;
    dotDir = config.home.homeDirectory;

    shellAliases = {
      tree = "eza --tree";
      cat = "bat";
      vi = "hx";
      cache-build = "nix build --json | jq -r '.[].outputs | to_entries[].value' | attic push --stdin oftaylor";
      cache-inputs = "nix flake archive --json | jq -r '.path,(.inputs|to_entries[].value.path)' | attic push --stdin oftaylor";
      cache-all = "cache-build && cache-inputs";
      jjba = "jj bookmark advance";
      jjbs = "jj bookmark set";
    };

    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "jj"
        "1password"
      ];
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      dark = true;
      hyperlinks = true;
    };
  };

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Taylor Thomas";
      };
      merge = {
        conflictstyle = "zdiff3";
      };
      core = {
        blame = "delta";
      };
    };
    ignores = [
      ".direnv/"
      ".aider*"
    ];
  };

  programs.jujutsu = {
    enable = true;
    settings = {
      user = {
        name = "Taylor Thomas";
      };
      ui = {
        pager = "delta";
        diff-formatter = ":git";
        merge-editor = "vscode";
      };
      revsets = {
        log = "present(@) | ancestors(immutable_heads().., 8) | present(trunk())";
        bookmark-advance-to = "@-";
      };
      templates = {
        commit_trailers = "format_signed_off_by_trailer(self)";
      };
      remotes.thomastaylor312 = {
        auto-track-bookmarks = "glob:*";
      };
    };
  };

  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
    };
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

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
}
