{ ... }: {
  config = rec {
    home.username = "taylor";
    home.homeDirectory = "/Users/${home.username}";

    home.packages = [ ];

    programs.git = { userEmail = "taylor@cosmonic.com"; };
  };
}
