{
  stdenv,
  lib,
  fetchFromGitHub,
  qt6,
}:
stdenv.mkDerivation rec {
  pname = "openfortivpn-webview-qt";
  version = "607dc949730f24611a6dba6c5c6cb9a5669fd7ac";

  src = fetchFromGitHub {
    owner = "gm-vm";
    repo = "openfortivpn-webview";
    rev = version;
    hash = "sha256-BNotbb2pL7McBm0SQwcgEvjgS2GId4HVaxWUz/ODs6w=";
  };
  sourceRoot = "source/openfortivpn-webview-qt";

  nativeBuildInputs = [qt6.wrapQtAppsHook qt6.qtwebengine qt6.qmake];
  buildPhase = ''
    qmake .
    make
  '';
  installPhase = ''
    # Create the bin directory in the output path
    mkdir -p $out/bin
    # Copy the binary to the bin directory in the output path
    cp openfortivpn-webview $out/bin/
  '';
  meta = {
    description = "Web browser to take SAML cookie for openfortivpn";
    homepage = "https://github.com/gm-vm/openfortivpn-webview/tree/main";
    license = lib.licenses.mit;
    maintainers = ["jonboh"];
  };
}
