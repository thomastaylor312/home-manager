{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "oftaylor";
  home.homeDirectory = "/Users/oftaylor";

  home.packages = [
    pkgs.bat
    pkgs.cloc
    pkgs.doctl
    pkgs.mtr
    pkgs.ripgrep
    pkgs.iperf3
    pkgs.delta
    pkgs.wget
    pkgs.nmap
    pkgs.zig
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
    sessionVariables = {
      MANPAGER = "sh -c 'col -bx | bat -l man -p'";
    };

    shellAliases = {
      tree = "eza --tree";
      cat = "bat";
      brewup = "brew update && brew upgrade && brew cleanup";
      vi = "hx";
    };

    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
      ];
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
    userEmail = "taylor@oftaylor.com";
    userName = "Taylor Thomas";

    extraConfig = {
      init = {
        defaultBranch = "master";
      };
      merge = {
        conflictstyle = "zdiff3"; 
      };
      core = {
        blame = "delta";
      };
    };
  };
  
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
    };
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
}
