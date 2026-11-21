{
  lib,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
}:
let
  sources = {
    aarch64-darwin = {
      url = "https://github.com/microsoft/apm/releases/download/v0.37.0/apm-darwin-arm64.tar.gz";
      sha256 = "f745692f886969bd4e8ed54c265214098fd014cf33e8856488528d13f6a6b590";
    };
    x86_64-darwin = {
      url = "https://github.com/microsoft/apm/releases/download/v0.37.0/apm-darwin-x86_64.tar.gz";
      sha256 = "e787df8210a8be413c2f373b2cbf56d65f9d5ed5e0a8bd3413ece17ac9489d89";
    };
  };
in
stdenvNoCC.mkDerivation {
  pname = "microsoft-apm";
  version = "0.37.0";

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
