{ pkgs, otel-tui, ... }:
let packages = (pkgs // import ./pkgs pkgs);
in {
  config = rec {
    home.username = "taylor";
    home.homeDirectory = "/Users/${home.username}";

    home.packages = with packages; [
      act
      clusterctl
      go
      k6
      k9s
      kind
      kubectl
      nats-server
      natscli
      oras
      redis
      shellcheck
      wasm-tools
      zstd
      kargo
      awscli2
      kubernetes-helm
      eksctl
      kustomize
      otel-tui
      docker-credential-gcr
      google-cloud-sdk
      gofumpt
      pgcli
      (azure-cli.withExtensions [ azure-cli.extensions.aks-preview ])
    ];

    nix.settings = {
      netrc-file = "/Users/${home.username}/.config/nix/netrc";
    };

    programs.git = { userEmail = "taylor.thomas@akuity.io"; };
    programs.jujutsu = {
      settings = { user = { email = "taylor.thomas@akuity.io"; }; };
    };

    programs.zsh.shellAliases = {
      cache-home-manager =
        "nix build .#homeConfigurations.${home.username}.activationPackage --json | jq -r '.[].outputs | to_entries[].value' | attic push --stdin oftaylor";
    };

    programs.vscode = {
      profiles.default.extensions = with packages.vscode-extensions; [
        packages.vscode-marketplace.adpyke.codesnap
        packages.vscode-marketplace.dracula-theme.theme-dracula
        github.vscode-github-actions
        ms-kubernetes-tools.vscode-kubernetes-tools
        packages.vscode-marketplace.bytecodealliance.wit-idl
        packages.vscode-marketplace.redhat.vscode-yaml
        ms-vscode-remote.remote-ssh
      ];
      profiles.default.userSettings = {
        "codesnap.containerPadding" = "0em";
        "codesnap.showWindowControls" = false;
      };
    };

    programs.kubecolor = {
      enable = true;
      enableAlias = true;
    };

    programs.zed-editor = {
      userSettings = {
        languages = {
          Go = {
            formatter = {
              external = {
                command = "gofumpt";
                args = [ "-w" ];
              };
            };
          };
        };
      };
    };
  };
}
