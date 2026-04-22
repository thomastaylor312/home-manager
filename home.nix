{
  pkgs,
  importPath,
  helixPkg,
  tuicrPkg,
  agePlugin1passPkg,
  obsidianSkillsPath,
  ...
}:

let
  obsidianSkillNames = builtins.attrNames (builtins.readDir "${obsidianSkillsPath}/skills");
  mkSkillEntries =
    prefix:
    builtins.listToAttrs (
      map (name: {
        name = "${prefix}/${name}";
        value.source = "${obsidianSkillsPath}/skills/${name}";
      }) obsidianSkillNames
    );
in
{
  imports = [
    ./common.nix
    importPath
  ];

  home.file = {
    ".local/bin/intensify" = {
      source = ./files/intensify;
      executable = true;
    };
    ".local/bin/codebase-status" = {
      source = ./files/codebase-status;
      executable = true;
    };
    ".local/bin/codebase-status-graph" = {
      source = ./files/codebase-status-graph;
      executable = true;
    };
    ".local/bin/copilot-signin" = {
      source = ./files/copilot-signin;
      executable = true;
    };
    ".config/age/1pass.key" = {
      source = ./files/1pass.key;
    };
  }
  // mkSkillEntries ".claude/skills"
  // mkSkillEntries ".codex/skills";

  home.packages = with pkgs; [
    docker
    iperf3
    dasel
    llama-cpp
    mtr
    nmap
    openai-whisper
    tuicrPkg
    agePlugin1passPkg
  ];

  programs.helix = {
    package = helixPkg;
    settings = {
      editor = {
        inline-completion-timeout = 150;
        inline-completion-auto-trigger = true;
      };
      keys.insert = {
        "A-tab" = "inline_completion_accept";
        "C-e" = "inline_completion_dismiss";
        "A-n" = "inline_completion_next";
        "A-p" = "inline_completion_prev";
      };
    };
  };

  programs.ghostty = {
    enable = true;
    systemd.enable = false;
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
      shell-integration-features = "ssh-terminfo";
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

  programs.vscode = {
    enable = true;
    profiles.default.extensions = with pkgs.vscode-extensions; [
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
      dracula-theme.theme-dracula
      pkgs.vscode-marketplace.sst-dev.opencode
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
          "nil" = {
            "formatting" = {
              "command" = [ "nixfmt" ];
            };
          };
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
        "inputs" = [
          {
            "type" = "promptString";
            "id" = "github_token";
            "description" = "GitHub Personal Access Token";
            "password" = true;
          }
        ];
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
            "args" = [
              "run"
              "-i"
              "--rm"
              "mcp/fetch"
            ];
          };
        };
      };
    };
  };
}
