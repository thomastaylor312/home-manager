{ pkgs, otel-tui, ... }:
let packages = (pkgs // import ./pkgs pkgs);
in {
  config = rec {
    home.username = "taylor";
    home.homeDirectory = "/Users/${home.username}";

    home.packages = [
      packages.act
      packages.clusterctl
      packages.go
      packages.k6
      packages.k9s
      packages.kind
      packages.kubectl
      packages.nats-server
      packages.natscli
      packages.oci-cli
      packages.oras
      packages.redis
      packages.shellcheck
      packages.wasm-tools
      packages.zstd
      otel-tui
      (packages.azure-cli.withExtensions
        [ packages.azure-cli.extensions.aks-preview ])
    ];

    nix.settings = {
      substituters = [ "https://wasmcloud.cachix.org" ];
      trusted-public-keys = [
        "wasmcloud.cachix.org-1:9gRBzsKh+x2HbVVspreFg/6iFRiD4aOcUQfXVDl3hiM="
      ];
      netrc-file = "/Users/${home.username}/.config/nix/netrc";
    };

    programs.git = { userEmail = "taylor@cosmonic.com"; };

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
  };
}
