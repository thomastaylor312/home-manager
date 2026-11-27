{
  lib,
  stdenv,
  autoPatchelfHook,
  alsa-lib,
  at-spi2-atk,
  cairo,
  cups,
  dbus,
  expat,
  glib,
  gtk3,
  libdrm,
  libgbm,
  libGL,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxkbcommon,
  libxrandr,
  nspr,
  nss,
  pango,
  systemd,
  vulkan-loader,
  version,
  # An upstream release tarball (not unpacked). It holds a complete install tree, signed on macOS,
  # so nothing is built here.
  src,
}:
let
  inherit (stdenv.hostPlatform) isDarwin isLinux;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "terminal-browser";
  inherit version src;

  # The macOS archive was made by macOS tar, which records extended attributes as AppleDouble `._*`
  # entries. Extracted anywhere but macOS tar they become real files inside the app bundle, which
  # breaks its code signature. The signatures that matter are embedded in the binaries and listed
  # in the bundle's CodeResources, so the attributes themselves aren't needed.
  unpackPhase = ''
    runHook preUnpack
    mkdir source
    tar -xzf $src -C source --strip-components 1 --exclude '._*' --warning=no-unknown-keyword
    cd source
    runHook postUnpack
  '';

  # The Linux release is a stock Electron tree plus a native addon and the agent-browser binary,
  # all linked against a conventional FHS system.
  nativeBuildInputs = lib.optionals isLinux [ autoPatchelfHook ];
  buildInputs = lib.optionals isLinux [
    alsa-lib
    at-spi2-atk
    cairo
    cups
    dbus
    expat
    glib
    gtk3
    libdrm
    libgbm
    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxkbcommon
    libxrandr
    nspr
    nss
    pango
    stdenv.cc.cc.lib
  ];
  # Loaded with dlopen at runtime, so autoPatchelf can't see that they're needed.
  runtimeDependencies = lib.optionals isLinux [
    libGL
    (lib.getLib systemd)
    vulkan-loader
  ];

  dontConfigure = true;
  dontBuild = true;
  # The macOS bundle is signed, so any rewriting there (shebangs, stripping) would invalidate it.
  # Linux needs the fixup phase for autoPatchelf, but stripping the prebuilt binaries buys nothing.
  dontFixup = isDarwin;
  dontStrip = true;

  # The upstream launcher finds its install tree from its own path, so it is exec'd from where it
  # lives rather than linked onto the PATH directly.
  #
  # `upgrade` would curl-pipe a fresh install into ~/.local, outside of Nix; refuse it so the only
  # way to move versions is bumping the flake input. `setup` installs the skill and saves the
  # answer to its prompt in a file home-manager owns, so it would fail partway through. The only
  # part of it still needed is the Linux AppArmor profile that lets Chromium's sandbox create user
  # namespaces. The profile is tied to the binary's store path, so it has to be redone for each
  # version (the browser also offers to do this itself on launch).
  installPhase = ''
    runHook preInstall

    if [ "$(cat VERSION)" != "v$version" ]; then
      echo "release tarball is $(cat VERSION), expected v$version" >&2
      exit 1
    fi

    root=$out/libexec/terminal-browser
    mkdir -p $out/libexec $out/bin
    cp -a . $root
    cat > $out/bin/terminal-browser <<EOF
    #!/bin/sh
    case "\$1" in
      upgrade)
        echo "terminal-browser is installed by home-manager; update its flake input instead" >&2
        exit 1
        ;;
      setup)
        ${
          if isLinux then
            "exec bash $root/scripts/apparmor.sh $root/electron/pixel"
          else
            ''echo "nothing to set up: home-manager installs the skill and editor settings"; exit 0''
        }
        ;;
    esac
    exec $root/bin/terminal-browser "\$@"
    EOF
    chmod +x $out/bin/terminal-browser

    runHook postInstall
  '';

  # The agent skill, in the release's two variants: `default`, and `codex` with extra guidance for
  # Codex's sandbox.
  passthru.skills = lib.genAttrs [ "default" "codex" ] (
    variant: "${finalAttrs.finalPackage}/libexec/terminal-browser/skills/${variant}/terminal-browser"
  );

  meta = {
    description = "A real browser that runs inside your terminal";
    homepage = "https://github.com/zenbu-labs/terminal-browser";
    license = lib.licenses.mit;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [
      "aarch64-darwin"
      "x86_64-linux"
    ];
    mainProgram = "terminal-browser";
  };
})
