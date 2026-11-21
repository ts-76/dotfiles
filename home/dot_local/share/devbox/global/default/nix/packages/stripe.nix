{
  lib,
  stdenvNoCC,
  fetchurl,
}:
let
  sources = {
    aarch64-darwin = {
      url = "https://github.com/stripe/stripe-cli/releases/download/v1.55.14/stripe_1.55.14_mac-os_arm64.tar.gz";
      sha256 = "97033ee87ab676b40213a19a71e40b5c22df924063ca1ec3edfe4aed155c8a15";
    };
    x86_64-darwin = {
      url = "https://github.com/stripe/stripe-cli/releases/download/v1.55.14/stripe_1.55.14_mac-os_x86_64.tar.gz";
      sha256 = "be2f54c652b14f7d0c0c38771bd163ddc6e1cbe1778b0eb0516b94ef876c33af";
    };
  };
in
stdenvNoCC.mkDerivation {
  pname = "stripe-cli";
  version = "1.55.14";

  src = fetchurl sources.${stdenvNoCC.hostPlatform.system};
  sourceRoot = ".";
  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 stripe "$out/bin/stripe"
    mkdir -p "$out/share/zsh/site-functions" "$out/share/bash-completion/completions" \
      "$out/share/fish/vendor_completions.d"
    export XDG_CONFIG_HOME="$TMPDIR/stripe-config"
    "$out/bin/stripe" completion --shell zsh --write-to-stdout > "$out/share/zsh/site-functions/_stripe"
    "$out/bin/stripe" completion --shell bash --write-to-stdout > "$out/share/bash-completion/completions/stripe"
    "$out/bin/stripe" completion --shell fish --write-to-stdout > "$out/share/fish/vendor_completions.d/stripe.fish"
    runHook postInstall
  '';

  meta = {
    description = "Command-line interface for Stripe";
    homepage = "https://github.com/stripe/stripe-cli";
    license = lib.licenses.asl20;
    mainProgram = "stripe";
    platforms = builtins.attrNames sources;
  };
}
