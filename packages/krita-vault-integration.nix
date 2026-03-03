{
  stdenv,
  fetchFromGitHub,
}:
stdenv.mkDerivation rec {
  pname = "krita-vault-integration";
  version = "9820f393b20dfa6725ba42d1d2851ab5fce1c971";

  src = fetchFromGitHub {
    owner = "jonboh";
    repo = "krita-vault-integration";
    rev = version;
    hash = "sha256-kikCkxnhZzqCuA4xM5mZqrzjcEcMP7RXNOCEJ+Ohx1A=";
  };

  installPhase = ''
    mkdir -p $out
    cp -r $src/* $out
  '';
}
