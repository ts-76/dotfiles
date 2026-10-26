{
  lib,
  stdenvNoCC,
  fetchurl,
}:
let
  sources = {
    aarch64-darwin = {
      url = "https://github.com/stripe/stripe-cli/releases/download/v1.40.9/stripe_1.40.9_mac-os_arm64.tar.gz";
      sha256 = "0efd6180c323fb8d5c26e4006ff8129c5cc44ca02541c3abde335bff15dc1759";
    };
    x86_64-darwin = {
      url = "https://github.com/stripe/stripe-cli/releases/download/v1.40.9/stripe_1.40.9_mac-os_x86_64.tar.gz";
      sha256 = "f3131b07918b5d3237c7474ff91b326b1852a8dc9eb5869819337201bd0b4eb4";
    };
  };
in
stdenvNoCC.mkDerivation {
  pname = "stripe-cli";
  version = "1.40.9";

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
