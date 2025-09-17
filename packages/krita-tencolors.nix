{
  stdenv,
  fetchFromGitHub,
}:
stdenv.mkDerivation rec {
  pname = "krita-tencolors";
  version = "2966ceb49ddb6b28eb01a001b50e0d410f771dba";

  src = fetchFromGitHub {
    owner = "jonboh";
    repo = "krita-tencolors";
    rev = version;
    hash = "sha256-smeBTv/AFDSFMw2AztljyLsDnfETeKjl7IpyX5M8lZg=";
  };

  installPhase = ''
    mkdir -p $out
    cp -r $src/* $out
  '';
}
