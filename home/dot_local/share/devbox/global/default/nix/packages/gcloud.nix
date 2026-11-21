{
  lib,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
  python313,
  openssl,
  cacert,
  jq,
}:

let
  version = "594.0.0";
  pythonEnv = python313.withPackages (ps: [
    ps.cffi
    ps.cryptography
    ps.pyopenssl
    ps.crcmod
    ps.grpcio
    ps.numpy
  ]);
  componentIndex = fetchurl {
    url = "https://dl.google.com/dl/cloudsdk/channels/rapid/components-v${version}.json";
    sha256 = "b7e357c5cafb6e4849724418dd70925f78b0d30a7b07d0e32b3bb126d184137e";
  };
  alpha = fetchurl {
    url = "https://dl.google.com/dl/cloudsdk/channels/rapid/components/google-cloud-sdk-alpha-20261113082344.tar.gz";
    sha256 = "73eeb0b0222c8c72ce1cbba3c2ca787d7d89eabc5226463fd59a404f76280138";
  };
in
stdenvNoCC.mkDerivation {
  pname = "google-cloud-sdk";
  inherit version;

  src = fetchurl {
    url = "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-${version}-darwin-arm.tar.gz";
    sha256 = "45fbcc5a2caf9ec43847383d2f9fe4720eb8a650349be8d9bd271bdfb6912b55";
  };

  nativeBuildInputs = [ makeWrapper jq ];
  buildInputs = [ pythonEnv ];
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    sdk="$out/share/google-cloud-sdk"
    mkdir -p "$sdk" "$out/bin"
    cp -R . "$sdk/"
    tar -xzf ${alpha} -C "$sdk"
    printf '%s\n' 'lib/surface/alpha/__init__.py' > "$sdk/.install/alpha.manifest"
    jq '{components: [.components[] | select(.id == "alpha")], revision, schema_version, version}' \
      ${componentIndex} > "$sdk/.install/alpha.snapshot.json"

    substituteInPlace "$sdk/lib/googlecloudsdk/core/config.json" \
      --replace-fail '"disable_updater": false' '"disable_updater": true'
    printf '\n[component_manager]\ndisable_update_check = true\n' >> "$sdk/properties"

    # Use the Nix Python extension rather than bundled wheels built for another interpreter.
    rm -rf "$sdk/platform/gsutil/third_party/crcmod" \
      "$sdk/platform/gsutil/third_party/crcmod_osx"

    for program in gcloud bq gsutil docker-credential-gcloud git-credential-gcloud.sh; do
      substituteInPlace "$sdk/bin/$program" \
        --replace-fail 'while _cloudsdk_link=$(readlink "$_cloudsdk_path")' \
          'while _cloudsdk_link=$(readlink "$_cloudsdk_path" 2>/dev/null)'
      makeWrapper "$sdk/bin/$program" "$out/bin/$program" \
        --set CLOUDSDK_PYTHON "${pythonEnv}/bin/python3" \
        --set CLOUDSDK_GSUTIL_PYTHON "${pythonEnv}/bin/python3" \
        --set CLOUDSDK_BQ_PYTHON "${pythonEnv}/bin/python3" \
        --set CLOUDSDK_PYTHON_ARGS "-S -B -W ignore" \
        --set PYTHONNOUSERSITE 1 \
        --set PYTHONPATH "${pythonEnv}/${python313.sitePackages}" \
        --set SSL_CERT_FILE "${cacert}/etc/ssl/certs/ca-bundle.crt" \
        --prefix PATH : "${openssl.bin}/bin"
    done
    ln -s "$out/bin/git-credential-gcloud.sh" "$out/bin/git-credential-gcloud"
    ln -s "$sdk/bin/gcloud-crc32c" "$out/bin/gcloud-crc32c"

    mkdir -p "$out/share/bash-completion/completions" "$out/share/zsh/site-functions"
    cp "$sdk/completion.bash.inc" "$out/share/bash-completion/completions/gcloud"
    { printf '#compdef gcloud\n'; cat "$sdk/completion.zsh.inc"; } \
      > "$out/share/zsh/site-functions/_gcloud"
    runHook postInstall
  '';

  meta = {
    description = "Google Cloud CLI with the existing alpha, bq, gsutil, and CRC32C components";
    homepage = "https://cloud.google.com/cli/";
    license = lib.licenses.asl20;
    mainProgram = "gcloud";
    platforms = [ "aarch64-darwin" ];
  };
}
