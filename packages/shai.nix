{
  lib,
  stdenv,
  openssl,
  fetchFromGitHub,
  rustPlatform,
}:
rustPlatform.buildRustPackage rec {
  pname = "shai";
  version = "v0.2.0";

  src = fetchFromGitHub {
    owner = "jonboh";
    repo = pname;
    rev = version;
    hash = "sha256-K+kNQUGG3B1YkrxH59/wvp9tQW89ax5IKc6nyQqbdhQ=";
  };

  cargoHash = "sha256-kZHHY5j2FeTFAgXlkrxsPMw2Tuh3mPeItcedHNoIOB8=";

  preConfigure = lib.optionalString stdenv.isLinux ''
    export OPENSSL_INCLUDE_DIR="${openssl.dev}/include"
    export OPENSSL_LIB_DIR="${lib.getLib openssl}/lib"
  '';

  meta = with lib; {
    description = "A shell AI assistant";
    homepage = "https://github.com/jonboh/shai";
    license = licenses.mit;
    maintainers = ["jonboh"];
  };
}
