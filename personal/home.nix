{ pkgs, ... }: {
  config = rec {
    home.username = "oftaylor";
    home.homeDirectory = "/Users/${home.username}";

    home.packages = [ pkgs.rclone pkgs.doctl ];

    programs.git = {
      userEmail = "taylor@oftaylor.com";
      userName = "Taylor Thomas";

      extraConfig = {
        init = { defaultBranch = "master"; };
        merge = { conflictstyle = "zdiff3"; };
        core = { blame = "delta"; };
      };
    };
  };
}
