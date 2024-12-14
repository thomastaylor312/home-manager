{ buildGoModule, fetchFromGitHub, versionCheckHook }:

buildGoModule rec {
  pname = "otel-tui";
  version = "0.3.8";

  env.GOWORK = "off";

  subPackages = [ "." ];

  src = fetchFromGitHub {
    owner = "ymtdzzz";
    repo = "otel-tui";
    rev = "refs/tags/v${version}";
    hash = "sha256-cZWKzXx42U4ouHl6+1SdD7WDD72v70AQW2aU7weUHWw=";
  };

  vendorHash = "sha256-D78I5/Hdgk6Ol1UTwp+IQi/+tkcYBacw9kNMNEkaWaU=";

  ldflags = [ "-X main.version=${version}" ];

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;
  versionCheckProgram = "${placeholder "out"}/bin/otel-tui";

  meta = {
    description = "OTEL Terminal User Interface";
    homepage = "https://github.com/ymtdzzz/otel-tui";
    changelog = "https://github.com/ymtdzzz/otel-tui/releases/tag/v${version}";
    mainProgram = "otel-tui";
  };
}
