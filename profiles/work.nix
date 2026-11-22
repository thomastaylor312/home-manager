{ pkgs, ... }:
{
  imports = [ ../modules/base.nix ];

  home.username = "taylor";

  home.packages = with pkgs; [
    act
    argocd
    awscli2
    clusterctl
    delve
    docker-credential-gcr
    eksctl
    go_1_26
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

  programs.git.settings = {
    user.email = "taylor.thomas@akuity.io";
    url."ssh://git@github.com/".insteadOf = "https://github.com/";
  };

  programs.jujutsu.settings.remotes.origin.auto-track-bookmarks = "glob:taylor/*";

  programs.kubecolor = {
    enable = true;
    enableAlias = true;
  };

  # Only takes effect in configurations that include the GUI module.
  programs.vscode.profiles.default = {
    extensions = with pkgs.vscode-extensions; [
      pkgs.vscode-marketplace.adpyke.codesnap
      github.vscode-github-actions
      ms-kubernetes-tools.vscode-kubernetes-tools
      pkgs.vscode-marketplace.bytecodealliance.wit-idl
      pkgs.vscode-marketplace.redhat.vscode-yaml
      ms-vscode-remote.remote-ssh
      hashicorp.terraform
    ];
    userSettings = {
      "codesnap.containerPadding" = "0em";
      "codesnap.showWindowControls" = false;
    };
  };
}
