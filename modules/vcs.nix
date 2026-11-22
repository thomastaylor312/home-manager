{ config, ... }:
{
  programs.git = {
    enable = true;
    settings = {
      # Each profile supplies `user.email`.
      user = {
        name = "Taylor Thomas";
      };
      merge = {
        conflictstyle = "zdiff3";
      };
      core = {
        blame = "delta";
      };
    };
    ignores = [
      ".direnv/"
      ".aider*"
    ];
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      dark = true;
      hyperlinks = true;
    };
  };

  programs.jujutsu = {
    enable = true;
    settings = {
      # jj commits under the same identity as git, so it only has to be set once.
      user = {
        inherit (config.programs.git.settings.user) name email;
      };
      ui = {
        pager = "delta";
        diff-formatter = ":git";
        merge-editor = "vscode";
      };
      revsets = {
        log = "present(@) | ancestors(immutable_heads().., 8) | present(trunk())";
        bookmark-advance-to = "@-";
      };
      templates = {
        commit_trailers = "format_signed_off_by_trailer(self)";
      };
      git = {
        # Refuse to push any commit whose description starts with "private:" so local-only
        # TODO/scratch commits can't leak to a remote.
        private-commits = "description(glob:'private:*')";
      };
      remotes.thomastaylor312 = {
        auto-track-bookmarks = "glob:*";
      };
      revset-aliases = {
        # Represents all commits on a "branch" between the trunk and the given change. Useful for rebases
        "branch(c)" = "fork_point(c|trunk())..c";
        # Root of the first-parent line from c down to trunk, i.e. "my side" of a stack that has
        # other branches merged into it. Relies on merges being created as `jj new mine theirs`.
        "stack_root(c)" = "roots(trunk()..c & first_ancestors(c))";
        "stack_root" = "stack_root(@)";
        # Roots of every branch merged into c's first-parent line ("their side"). To rebase both
        # sides at once, use `jj rebase -b @ -o trunk()` instead.
        "merged_roots(c)" = "roots(trunk()..c ~ first_ancestors(c))";
      };

      aliases = {
        rebase-all = [
          "rebase"
          "-s"
          "(::trunk())+ & mutable()"
          "-o"
          "trunk()"
        ];
        rebase-current = [
          "rebase"
          "-r"
          "branch(@)"
          "-o"
          "trunk()"
        ];
        difft = [
          "diff"
          "--tool"
          "difft"
        ];
        resolvem = [
          "resolve"
          "--tool"
          "mergiraf"
        ];
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
}
