{
  stdenv,
  fetchFromGitHub,
}:
stdenv.mkDerivation rec {
  pname = "anki-open-vault-reference";
  version = "0.0.0";
  src = fetchFromGitHub {
    owner = "jonboh";
    repo = "anki-open-vault-reference";
    rev = "c7cb178c0d8659a8ee596f0b25f5f41bb9391da5";
    sha256 = "sha256-TNAcbckhdDE8P35uMW48zIg4uB4JISdMQ3TT2Qu47Ig=";
  };
  installPhase = ''
    mkdir -p $out
    cp -r $src/* $out
  '';
}
