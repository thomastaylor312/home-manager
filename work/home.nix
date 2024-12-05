{ pkgs, ... }: {
  config = rec {
    home.username = "taylor";
    home.homeDirectory = "/Users/${home.username}";

    home.packages = [ pkgs.kubectl pkgs.kind pkgs.redis pkgs.oras pkgs.zstd pkgs.natscli pkgs.nats-server ];

    programs.git = { userEmail = "taylor@cosmonic.com"; };

    programs.vscode = {
      extensions = with pkgs.vscode-extensions; [
        pkgs.vscode-marketplace.adpyke.codesnap
        pkgs.vscode-marketplace.dracula-theme.theme-dracula
        github.vscode-github-actions
        pkgs.vscode-marketplace-release.eamodio.gitlens
        ms-kubernetes-tools.vscode-kubernetes-tools
        pkgs.vscode-marketplace.bytecodealliance.wit-idl
        pkgs.vscode-marketplace.redhat.vscode-yaml
        ms-vscode-remote.remote-ssh
      ];
    };
  };
}
