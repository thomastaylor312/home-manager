{ buildGoModule, fetchFromGitHub, versionCheckHook }:

buildGoModule rec {
  pname = "otel-tui";
  version = "0.4.1";

  env.GOWORK = "off";

  subPackages = [ "." ];

  src = fetchFromGitHub {
    owner = "ymtdzzz";
    repo = "otel-tui";
    rev = "refs/tags/v${version}";
    hash = "sha256-oe0V/iTo7LPbajLVRbjQTTqDaht/SnONAaaKwrMWRKI=";
  };

  vendorHash = "sha256-yUD+9tvBr2U1U7+WXqz6sKt9EBXGQCWVyYRYCDRENf4=";

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
