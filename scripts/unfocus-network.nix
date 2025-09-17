{pkgs, ...}:
pkgs.writeShellScriptBin "unfocus-network" ''
  sed -i '/youtube.com/d' /etc/hosts
  sed -i '/linkedin.com/d' /etc/hosts
''
