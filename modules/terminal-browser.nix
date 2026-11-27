# terminal-browser: Chromium rendered into the terminal over the kitty graphics protocol, plus the
# agent skill for driving it.
{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  # Upstream publishes a release per platform; these are the ones wired in as flake inputs.
  inputNames = {
    aarch64-darwin = "terminal-browser-darwin-arm64";
    x86_64-linux = "terminal-browser-linux-x64";
  };
  inputName = inputNames.${pkgs.stdenv.hostPlatform.system} or null;

  # The release URL in flake.nix is the only place the version is written down.
  releaseUrl = (lib.importJSON ../flake.lock).nodes.${inputName}.original.url;

  terminal-browser = pkgs.callPackage ../pkgs/terminal-browser.nix {
    src = inputs.${inputName};
    version = lib.head (builtins.match ".*/v([^/]+)/[^/]+" releaseUrl);
  };
in
lib.mkIf (inputName != null) {
  home.packages = [ terminal-browser ];

  agentSkills.terminal-browser = terminal-browser.skills.default;
  # Adds a note telling Codex to escalate permissions when running the CLI, since its sandbox
  # blocks how terminal-browser finds the terminal pane it was launched from.
  agentSkillVariants.codex.terminal-browser = terminal-browser.skills.codex;

  # On first run of each version, terminal-browser links its skill into every agent's skills
  # directory, replacing whatever symlink is there, which would clobber the one home-manager owns
  # above. Recording "no" for its install prompt makes it skip that step.
  xdg.stateFile."terminal-browser/skills-choice".text = "no\n";

  # The same first-run step turns this on in every VS Code-style editor by renaming a rewritten
  # settings.json over the old one, which would replace home-manager's symlink with a plain file.
  # It leaves the file alone when the setting is already true. Only takes effect in configurations
  # that include the GUI module.
  programs.vscode.profiles.default.userSettings."terminal.integrated.enableImages" = true;
}
