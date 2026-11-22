# The command-line environment shared by every configuration.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./agents.nix
    ./helix.nix
    ./shell.nix
    ./vcs.nix
  ];

  # Profiles only set the username; the home directory follows from it and the platform.
  home.homeDirectory =
    (if pkgs.stdenv.hostPlatform.isDarwin then "/Users" else "/home") + "/${config.home.username}";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "26.05";

  home.packages =
    with pkgs;
    [
      age
      inputs.age-plugin-1pass.packages.${stdenv.hostPlatform.system}.default
      bat
      cachix
      cloc
      cue
      dasel
      defuddle
      delta
      difftastic
      docker
      ffmpeg
      hack-font
      helm-ls
      hexyl
      imagemagick
      iperf3
      jjui
      jq
      just
      llama-cpp
      mergiraf
      mtr
      nmap
      nodejs_24
      (callPackage ../pkgs/playwright-cli.nix { src = inputs.playwright-cli-src; })
      # PDF-to-image converter, useful for claude stuff when analyzing docs
      poppler-utils
      protobuf
      python314
      scooter
      tailscale
      uv
      wget
    ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [ _1password-cli ];

  home.file = {
    ".config/age/1pass.key".source = ../files/1pass.key;
    ".config/rex" = {
      source = ../files/rex;
      recursive = true;
    };
  }
  # Every script in files/bin goes on the PATH.
  // lib.mapAttrs' (
    name: _:
    lib.nameValuePair ".local/bin/${name}" {
      source = ../files/bin + "/${name}";
      executable = true;
    }
  ) (builtins.readDir ../files/bin);

  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.cargo/bin"
  ];

  home.sessionVariables = {
    GH_TELEMETRY = "false";
    DO_NOT_TRACK = "true";
  };

  # Determinate manages /etc/nix and the daemon; substituters go in /etc/nix/nix.custom.conf, not here.
  nix.enable = false;

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  fonts.fontconfig.enable = true;

  programs.btop = {
    enable = true;
    settings = {
      color_theme = "dracula";
    };
  };

  programs.fd.enable = true;

  programs.ripgrep = {
    enable = true;
    arguments = [ "--hidden" ];
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
      dracula = inputs.dracula-yazi;
    };
  };
}
