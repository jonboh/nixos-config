{
  stdenv,
  fetchFromGitHub,
}:
stdenv.mkDerivation rec {
  pname = "krita-vault-integration";
  version = "986206cb2de36b64016f098335a1f4d5b8e38215";

  src = fetchFromGitHub {
    owner = "jonboh";
    repo = "krita-vault-integration";
    rev = version;
    hash = "sha256-SBCzsdrzqXDtrMpb8EjBuoqnpijygRGw+9wIErR3qBo=";
  };

  installPhase = ''
    mkdir -p $out
    cp -r $src/* $out
  '';
}
