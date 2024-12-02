{ pkgs, ... }: {
  config = rec {
    home.username = "taylor";
    home.homeDirectory = "/Users/${home.username}";

    home.packages = [ pkgs.kubectl pkgs.kind ];

    programs.git = { userEmail = "taylor@cosmonic.com"; };
  };
}
