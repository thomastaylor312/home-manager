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
      # Temporary due to nixpkgs build failure
      #pgcli
      kubelogin-oidc
      delve
      upbound
      # Another temporary break
      #(azure-cli.withExtensions [ azure-cli.extensions.aks-preview ])
    ];

    nix.settings = {
      netrc-file = "/Users/${home.username}/.config/nix/netrc";
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
