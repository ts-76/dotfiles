{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
}:
let
  sources = {
    aarch64-darwin = {
      url = "https://github.com/k1LoW/mo/releases/download/v1.8.2/mo_v1.8.2_darwin_arm64.zip";
      sha256 = "4c2968a9ab02f3687ea81961085c106f232a2c63ba5088ec819b3955a1424c5e";
    };
    x86_64-darwin = {
      url = "https://github.com/k1LoW/mo/releases/download/v1.8.2/mo_v1.8.2_darwin_amd64.zip";
      sha256 = "d833f1e5450a8e5cce383c371c1b9b268baddd2cdc0ca32cb6eb765d0272e0b3";
    };
    aarch64-linux = {
      url = "https://github.com/k1LoW/mo/releases/download/v1.8.2/mo_v1.8.2_linux_arm64.tar.gz";
      sha256 = "49eef17ba90bf8cbd8ed65c36955d5a7f5572b372bbf0ee1a3f51e2fbec34781";
    };
    x86_64-linux = {
      url = "https://github.com/k1LoW/mo/releases/download/v1.8.2/mo_v1.8.2_linux_amd64.tar.gz";
      sha256 = "3b8a35b89c41df05a5769b3b7fb13e3ffef358c5e990e89520487218a268fcf1";
    };
  };
in
stdenvNoCC.mkDerivation {
  pname = "mo-markdown";
  version = "1.8.2";

  src = fetchurl sources.${stdenvNoCC.hostPlatform.system};
  sourceRoot = ".";
  nativeBuildInputs = [ unzip ];
  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 mo "$out/bin/mo"
    install -Dm644 LICENSE "$out/share/licenses/mo/LICENSE"
    mkdir -p "$out/share/zsh/site-functions" "$out/share/bash-completion/completions"
    "$out/bin/mo" completion zsh > "$out/share/zsh/site-functions/_mo"
    "$out/bin/mo" completion bash > "$out/share/bash-completion/completions/mo"
    runHook postInstall
  '';

  meta = {
    description = "Markdown viewer that opens files in a browser";
    homepage = "https://github.com/k1LoW/mo";
    license = lib.licenses.mit;
    mainProgram = "mo";
    platforms = builtins.attrNames sources;
  };
}
