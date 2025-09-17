{pkgs, ...}:
pkgs.writeShellScriptBin "focus-network" ''
  echo "127.0.0.1 youtube.com www.youtube.com" | tee -a /etc/hosts
  echo "127.0.0.1 linkedin.com www.linkedin.com" | tee -a /etc/hosts
''
