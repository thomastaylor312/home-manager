{
  homeDirectoryBase,
  username,
  ...
}:
{
  imports = [ ./common.nix ];

  home.username = username;
  home.homeDirectory = "${homeDirectoryBase}/${username}";

  programs.git.settings.user.email = "taylor@oftaylor.com";
  programs.jujutsu.settings.user.email = "taylor@oftaylor.com";
}
