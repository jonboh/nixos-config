{
  lib,
  fetchFromGitLab,
  rustPlatform,
}:
rustPlatform.buildRustPackage rec {
  pname = "simple-thumbnailer-stl";
  version = "v0.1.0";

  src = fetchFromGitLab {
    owner = "zoli111";
    repo = pname;
    rev = "e563a4c6cff4d3ebf45dc4f080261072115b92e7";
    hash = "sha256-gvRWa2ztFHJEF94kaYEOyIvdVYHqHSO4E2/rtYbIjQY=";
  };
  cargoPatches = [
    # a patch file to add/update Cargo.lock in the source code
    ./add-Cargo.lock.patch
  ];
  cargoHash = "sha256-ANyR/ZQI0MFyGzxrHuGUHNrlVv3dQ+P/chFOhdHjsK0=";

  meta = with lib; {
    description = "Thumbnail generator for STL files";
    homepage = "https://gitlab.com/zoli111/simple-thumbnailer-stl";
    license = licenses.gpl3;
    maintainers = ["jonboh"];
  };
}
