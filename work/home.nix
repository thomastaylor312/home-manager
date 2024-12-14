{ pkgs, ... }:
let packages = (pkgs // import ./pkgs pkgs);
in {
  config = rec {
    home.username = "taylor";
    home.homeDirectory = "/Users/${home.username}";

    home.packages = [
      packages.kubectl
      packages.kind
      packages.redis
      packages.oras
      packages.zstd
      packages.natscli
      packages.nats-server
      packages.k6
      packages.k9s
      packages.otel-tui
    ];

    programs.git = { userEmail = "taylor@cosmonic.com"; };

    programs.vscode = {
      extensions = with packages.vscode-extensions; [
        packages.vscode-marketplace.adpyke.codesnap
        packages.vscode-marketplace.dracula-theme.theme-dracula
        github.vscode-github-actions
        packages.vscode-marketplace-release.eamodio.gitlens
        ms-kubernetes-tools.vscode-kubernetes-tools
        packages.vscode-marketplace.bytecodealliance.wit-idl
        packages.vscode-marketplace.redhat.vscode-yaml
        ms-vscode-remote.remote-ssh
      ];
    };

    programs.kubecolor = {
      enable = true;
      enableAlias = true;
    };
  };
}
