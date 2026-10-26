{
  lib,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
}:
let
  sources = {
    aarch64-darwin = {
      url = "https://github.com/microsoft/apm/releases/download/v0.16.1/apm-darwin-arm64.tar.gz";
      sha256 = "57771452f017aba208351ab1d0b384273c463faf2bb4516c94eba422a4fe028d";
    };
    x86_64-darwin = {
      url = "https://github.com/microsoft/apm/releases/download/v0.16.1/apm-darwin-x86_64.tar.gz";
      sha256 = "96f04ea961ea0bf3885906fb6475695347a6de5d6ff2c46d3e641453e7c68ae9";
    };
  };
in
stdenvNoCC.mkDerivation {
  pname = "microsoft-apm";
  version = "0.16.1";

  src = fetchurl sources.${stdenvNoCC.hostPlatform.system};
  nativeBuildInputs = [ makeWrapper ];
  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;
  dontPatchShebangs = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/libexec/apm" "$out/bin"
    cp -a . "$out/libexec/apm/"
    makeWrapper "$out/libexec/apm/apm" "$out/bin/apm"
    runHook postInstall
  '';

  meta = {
    description = "Microsoft Agent Package Manager";
    homepage = "https://github.com/microsoft/apm";
    license = lib.licenses.mit;
    mainProgram = "apm";
    platforms = builtins.attrNames sources;
  };
}
