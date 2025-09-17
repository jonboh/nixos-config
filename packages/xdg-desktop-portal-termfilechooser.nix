{pkgs ? import <nixpkgs> {}}:
pkgs.stdenv.mkDerivation rec {
  pname = "xdg-desktop-portal-termfilechooser";
  version = "71dc7ab06751e51de392b9a7af2b50018e40e062";

  src = pkgs.fetchFromGitHub {
    owner = "GermainZ";
    repo = pname;
    rev = version;
    hash = "sha256-645hoLhQNncqfLKcYCgWLbSrTRUNELh6EAdgUVq3ypM=";
  };

  strictDeps = true;
  depsBuildBuild = with pkgs; [pkg-config];
  nativeBuildInputs = with pkgs; [
    meson
    ninja
    pkg-config
    scdoc
    wayland-scanner
    makeWrapper
  ];
  buildInputs = with pkgs; [
    inih
    libdrm
    mesa
    systemd
    wayland
    wayland-protocols
  ];

  mesonFlags = [
    "-Dsd-bus-provider=libsystemd"
    # "-Dman-pages"
  ];
  meta = {
    description = "xdg-desktop-portal backend for choosing files with your favorite file chooser";
    homepage = "https://github.com/GermainZ/xdg-desktop-portal-termfilechooser";
    license = pkgs.lib.licenses.mit;
  };
}
