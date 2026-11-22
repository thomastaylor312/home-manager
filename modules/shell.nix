{ config, lib, ... }:
let
  # Starship's built-in git modules. Each is disabled and re-exposed as a custom module that stays
  # quiet inside jj repos, where the jj module already shows the same information.
  gitModules = [
    "git_branch"
    "git_state"
    "git_commit"
    "git_metrics"
  ];
in
{
  programs.zsh = {
    enable = true;

    autosuggestion.enable = true;
    # Keep the zsh dotfiles directly in $HOME; from state version 26.05 the default moves them under
    # the XDG config directory when xdg is enabled.
    dotDir = config.home.homeDirectory;

    profileExtra = ''
      # Added by OrbStack: command-line tools and integration
      source ~/.orbstack/shell/init.zsh 2>/dev/null || :
    '';

    shellAliases = {
      tree = "eza --tree";
      cat = "bat";
      vi = "hx";
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

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings =
      lib.genAttrs gitModules (_: {
        disabled = true;
      })
      // {
        custom =
          lib.genAttrs gitModules (module: {
            when = true;
            command = "jj root --ignore-working-copy >/dev/null 2>&1 || starship module ${module}";
            description = "Only show ${module} if we're not in a jj repo";
          })
          // {
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
          };
      };
  };

  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      sync_address = "https://imperial-archives.dojo-nominal.ts.net";
      sync_frequency = "5m";
      enter_accept = true;
      store_failed = true;
      search_mode = "daemon-fuzzy";
      daemon = {
        enabled = true;
        autostart = true;
      };
      threads = {
        enabled = true;
        capture = true;
      };
      ai.enabled = true;
      # Turning this off for now, even though it's what keeps atuin's search UI from wiping out my
      # screen. The proxy sits between Rex and my shell, so Rex only ever sees login/atuin as the
      # foreground process and every single tab gets the generic icon. Atuin is working on titling
      # the terminal after the real program (atuinsh/atuin#4447), but Rex picks icons from the
      # process and not the title, so this can go back on once Rex can use one of those signals.
      pty_proxy.enabled = false;
    };
  };

  # Also sets $PAGER, which delta and bat fall back to when no pager of their own is configured.
  programs.moor = {
    enable = true;
    # Print short output (e.g. `jj status`) directly instead of opening the pager, matching `less -F`.
    options.quit-if-one-screen = true;
    options.wrap = true;
  };

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
    historyWidget.command = "";
  };
}
