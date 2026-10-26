{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
}:
let
  sources = {
    aarch64-darwin = {
      url = "https://github.com/k1LoW/mo/releases/download/v1.6.7/mo_v1.6.7_darwin_arm64.zip";
      sha256 = "83c0efa272b3044c8189f6ffb74bc6ecb20e3d9299eed476e63ee72d149643f4";
    };
    x86_64-darwin = {
      url = "https://github.com/k1LoW/mo/releases/download/v1.6.7/mo_v1.6.7_darwin_amd64.zip";
      sha256 = "376cb36b3e3b4e0075fa7f0b37685d9df9b56d4bd80e2d99596ab8e5a46932f6";
    };
    aarch64-linux = {
      url = "https://github.com/k1LoW/mo/releases/download/v1.6.7/mo_v1.6.7_linux_arm64.tar.gz";
      sha256 = "90b3fc49d38d73d5acc9b1ac6d1a992ffba5bf4d12787c2e645411af2993b8ce";
    };
    x86_64-linux = {
      url = "https://github.com/k1LoW/mo/releases/download/v1.6.7/mo_v1.6.7_linux_amd64.tar.gz";
      sha256 = "130666a7c8dfd1528d07f87b21adf5bfc1314707889e85ebbab1a5248d7ded11";
    };
  };
in
stdenvNoCC.mkDerivation {
  pname = "mo-markdown";
  version = "1.6.7";

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
