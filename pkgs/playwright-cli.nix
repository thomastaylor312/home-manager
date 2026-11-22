{
  lib,
  buildNpmPackage,
  makeWrapper,
  playwright-driver,
  # The upstream repository at the tag to build; the version is read from its package.json.
  src,
}:
buildNpmPackage {
  pname = "playwright-cli";
  inherit ((lib.importJSON "${src}/package.json")) version;
  inherit src;

  # Has to be refreshed whenever `src` moves to a new tag.
  npmDepsHash = "sha256-DK+nTRdVKznerAMK7McCCgr2OK4GXymbmgyR9qU/aH4=";

  dontNpmBuild = true;

  env = {
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";
    PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true";
  };

  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    wrapProgram $out/bin/playwright-cli \
      --set PLAYWRIGHT_BROWSERS_PATH ${playwright-driver.browsers} \
      --set PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS true
  '';

  meta = {
    description = "CLI for common Playwright actions";
    homepage = "https://github.com/microsoft/playwright-cli";
    license = lib.licenses.asl20;
    mainProgram = "playwright-cli";
  };
}
