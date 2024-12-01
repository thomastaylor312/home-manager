{ ... }: {
  config = rec {
    home.username = "taylor";
    home.homeDirectory = "/Users/${home.username}";

    home.packages = [ ];

    programs.git = {
      userEmail = "taylor@cosmonic.com";

      extraConfig = {
        init = { defaultBranch = "master"; };
        merge = { conflictstyle = "zdiff3"; };
        core = { blame = "delta"; };
      };
    };
  };
}
