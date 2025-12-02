{ pkgs, otel-tui, homeDirectoryBase, ... }:
let packages = (pkgs // import ./pkgs pkgs);
in {
  config = rec {
    home.username = "taylor";
    home.homeDirectory = "${homeDirectoryBase}/${home.username}";

    home.packages = with packages; [
      act
      awscli2
      clusterctl
      delve
      docker-credential-gcr
      eksctl
      go
      gofumpt
      google-cloud-sdk
      k6
      k9s
      kargo
      kind
      kubectl
      kubelogin-oidc
      kubernetes-helm
      kustomize
      nats-server
      natscli
      oras
      otel-tui
      pgcli
      redis
      shellcheck
      tilt
      upbound
      wasm-tools
      zstd
      # Another temporary break
      #(azure-cli.withExtensions [ azure-cli.extensions.aks-preview ])
    ];

    nix.settings = {
      netrc-file = "${homeDirectoryBase}/${home.username}/.config/nix/netrc";
    };

    programs.git = {
      settings = {
        user = { email = "taylor.thomas@akuity.io"; };
        url = {
          "ssh://git@github.com/" = { insteadOf = "https://github.com/"; };
        };
      };
    };
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
        github.vscode-github-actions
        ms-kubernetes-tools.vscode-kubernetes-tools
        packages.vscode-marketplace.bytecodealliance.wit-idl
        packages.vscode-marketplace.redhat.vscode-yaml
        ms-vscode-remote.remote-ssh
        hashicorp.terraform
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
  };
}
