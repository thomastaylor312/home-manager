# The AI coding agents, along with their shared instructions, subagents and skills.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  # Each agent reads the same skill format from its own directory.
  skillDirs = {
    claude = ".claude/skills";
    codex = ".codex/skills";
  };

  obsidianSkills = "${inputs.obsidian-skills}/plugins/obsidian/skills";

  # Generated at build time so new shells don't pay for launching omp just to produce completions.
  ompZshCompletions = pkgs.runCommand "omp-zsh-completions" { } ''
    export HOME="$TMPDIR"
    mkdir -p "$out/share/zsh/site-functions"
    ${config.programs.omp.package}/bin/omp completions zsh > "$out/share/zsh/site-functions/_omp"
  '';
in
{
  imports = [ inputs.omp.homeManagerModules.default ];

  options.agentSkills = lib.mkOption {
    type = lib.types.attrsOf lib.types.path;
    default = { };
    example = lib.literalExpression "{ my-skill = ./files/skills/my-skill; }";
    description = ''
      Skill directories, keyed by skill name. Each one is linked into the skills directory of every
      coding agent, so any module can contribute skills without knowing which agents exist.
    '';
  };

  options.agentSkillVariants = lib.mkOption {
    type = lib.types.attrsOf (lib.types.attrsOf lib.types.path);
    default = { };
    example = lib.literalExpression "{ codex.my-skill = ./files/skills/my-skill-codex; }";
    description = ''
      Per-agent replacements for entries in `agentSkills`, keyed by agent and then skill name, for
      skills that ship a copy tailored to one agent. Agents without an entry get the `agentSkills`
      copy.
    '';
  };

  config = {
    agentSkills = {
      gh-notifications-triage = ../files/skills/gh-notifications-triage;
      writing-style = ../files/skills/writing-style;
    }
    // lib.mapAttrs (name: _: "${obsidianSkills}/${name}") (builtins.readDir obsidianSkills);

    home.packages = [ ompZshCompletions ];

    home.file = {
      ".claude/CLAUDE.md".source = ../files/GLOBAL_AGENTS.md;
      ".claude/agents/code-review.md".source = ../files/agents/claude-code-review.md;
      ".codex/AGENTS.md".source = ../files/GLOBAL_AGENTS.md;
      # This might not work because it references claude specific tools, but figured I might as well
      # try it out
      ".codex/prompts/code-review.md".source = ../files/agents/claude-code-review.md;
      # Only overrides go here; omp merges this onto its built-in server list, which already covers the
      # other language servers installed for helix.
      ".omp/agent/lsp.json".text = builtins.toJSON {
        servers.taplo = {
          command = "taplo";
          args = [
            "lsp"
            "stdio"
          ];
          fileTypes = [ ".toml" ];
          # omp only checks the launch directory for these, so include common repo roots alongside
          # taplo's own config files.
          rootMarkers = [
            ".taplo.toml"
            "taplo.toml"
            ".git"
            ".jj"
          ];
        };
      };
    }
    // lib.concatMapAttrs (
      name: source:
      lib.mapAttrs' (
        agent: dir:
        lib.nameValuePair "${dir}/${name}" {
          source = config.agentSkillVariants.${agent}.${name} or source;
        }
      ) skillDirs
    ) config.agentSkills;

    programs.omp.enable = true;

    programs.opencode = {
      enable = true;
      context = ../files/GLOBAL_AGENTS.md;
    };
  };
}
