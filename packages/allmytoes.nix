{
  lib,
  # fetchFromGitLab,
  fetchFromGitHub,
  rustPlatform,
}:
rustPlatform.buildRustPackage rec {
  pname = "allmytoes";
  version = "a2b7d7770c098f90a01a9019a9c6b7efb542736a";

  # src = fetchFromGitLab {
  #   owner = "allmytoes";
  #   repo = pname;
  #   rev = version;
  #   hash = "sha256-BlvgCfs94PibvTbh3WaSfrxs+30uggZ7Dz0tmhh9jNk=";
  # };
  src = fetchFromGitHub {
    owner = "jonboh";
    repo = pname;
    rev = version;
    hash = "sha256-WPMHuKPx5xkxFmPof42/OYf8659cOvPjcANvbOvg378=";
  };
  cargoHash = "sha256-eP2b797rZ1crCofTbx/9hXSlTUUhNuLB8+rrb7xTFKA=";

  meta = with lib; {
    # description = "Thumbnail generator for STL files";
    # homepage = "https://gitlab.com/allmytoes/allmytoes";
    license = licenses.gpl3;
    maintainers = ["jonboh"];
  };
}
