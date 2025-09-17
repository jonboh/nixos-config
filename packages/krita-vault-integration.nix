{
  stdenv,
  fetchFromGitHub,
}:
stdenv.mkDerivation rec {
  pname = "krita-vault-integration";
  version = "689cf2a0d424c741a9ce2bfa0eaf983c06794a20";

  src = fetchFromGitHub {
    owner = "jonboh";
    repo = "krita-vault-integration";
    rev = version;
    hash = "sha256-5fdDro2MHh8/gQ1Jg4FzM6IRYwGYNhbkQUSEuiRE8eI=";
  };

  installPhase = ''
    mkdir -p $out
    cp -r $src/* $out
  '';
}
