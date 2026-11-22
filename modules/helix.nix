{ inputs, pkgs, ... }:
let
  # Every language gets Copilot alongside its own servers, so only the language-specific parts are
  # spelled out below.
  language =
    name: servers: extra:
    {
      inherit name;
      language-servers = servers ++ [ "copilot" ];
    }
    // extra;
in
{
  # The language servers and formatters referenced below. They are installed for the whole
  # environment rather than wrapped into helix because the other editors and agents use them too.
  home.packages = with pkgs; [
    bash-language-server
    copilot-language-server
    (lib.hiPrio gopls)
    gotools
    harper
    marksman
    nil
    nixfmt
    taplo
    terraform-ls
    typescript-language-server
    vscode-json-languageserver
    yaml-language-server
    zig
    zls
  ];

  programs.helix = {
    enable = true;
    defaultEditor = true;
    # A fork that adds inline (ghost text) completions, configured by the `inline-completion`
    # settings below.
    package = inputs.helix.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
      grammarOverlays = [
        # tree-sitter-perl defines its own bsearch(), which collides with the C23
        # const-generic bsearch macro in glibc >= 2.43. Build it as C17 instead.
        (_: prev: {
          perl = prev.perl.overrideAttrs (old: {
            FLAGS = old.FLAGS ++ [ "-std=gnu17" ];
          });
        })
      ];
    };
    settings = {
      theme = "dracula";
      editor = {
        inline-completion-timeout = 150;
        inline-completion-auto-trigger = true;
        file-picker = {
          hidden = false;
          git-ignore = false;
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
          "A-tab" = "inline_completion_accept";
          "C-e" = "inline_completion_dismiss";
          "A-n" = "inline_completion_next";
          "A-p" = "inline_completion_prev";
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
          "C-y" = [
            ":sh rm -f /tmp/yazi-helix"
            ":insert-output [[ %{buffer_name} == \"[scratch]\" ]] && yazi %{current_working_directory} --chooser-file=/tmp/yazi-helix || yazi %{buffer_name} --chooser-file=/tmp/yazi-helix" # if this is a [scratch] buffer, open yazi in working directory instead
            ":insert-output echo \"\x1b[?1049h\x1b[?2004h\" > /dev/tty" # These sequences help restore proper terminal state after Yazi exits: \x1b[?1049h switches to alternate screen buffer | \x1b[?2004h enables bracketed paste mode
            ":open %sh{cat /tmp/yazi-helix}" # Reads the file path that Yazi saved to the temp file
            ":redraw" # Necessary after running external terminal programs to fix visual artifacts
            # manage conflict of mouse integration between helix and yazi
            ":set mouse false"
            ":set mouse true"
          ];
        };
      };
    };
    languages = {
      language = [
        (language "nix" [ "nil" ] {
          formatter.command = "nixfmt";
          auto-format = true;
        })
        (language "rust" [ "rust-analyzer" ] { })
        (language "bash" [ "bash-language-server" ] { })
        (language "docker-compose" [ "yaml-language-server" ] { })
        (language "go" [ "gopls" ] { formatter.command = "goimports"; })
        (language "hcl" [ "terraform-ls" ] { })
        (language "javascript" [ "typescript-language-server" ] { })
        (language "jsx" [ "typescript-language-server" ] { })
        (language "typescript" [ "typescript-language-server" ] { })
        (language "zig" [ "zls" ] { })
        (language "markdown" [ "marksman" "harper" ] { })
        (language "yaml" [ "yaml-language-server" ] {
          indent = {
            tab-width = 2;
            unit = " ";
          };
        })
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
}
