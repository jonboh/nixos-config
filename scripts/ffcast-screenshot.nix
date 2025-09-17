{pkgs ? import <nixpkgs> {}}:
pkgs.writeShellScriptBin "ffcast-screenshot" ''
  # Check if recorging was on course
  ps aux --sort=start_time | grep 'ffcast-screenshot' | grep -v "grep" | awk '{print $2}' | grep -v $$ | tr -d '\n' > /tmp/.ffcastpid
  pid_ffcast=$(</tmp/.ffcastpid)
  if [ -n "$pid_ffcast" ]; then
    pid_ffmpeg=$(ps --no-headers -o pid --ppid=$(ps --no-headers -o pid --ppid=$pid_ffcast | tr -d '[:space:]' ))
    kill -SIGINT -- $pid_ffmpeg
  else
    selection=$(${pkgs.ffcast}/bin/ffcast -s)
    windowid=$(${pkgs.xdotool}/bin/xdotool getmouselocation --shell | tail -n 1 | awk -F '=' '{print $2}')
    prefix=$(echo $selection | awk -F '+' '{print $1}')

    filename=$HOME/screenshots/$(date '+%Y-%m-%d-%H_%M_%S.mp4')
    mkdir -p $HOME/screenshots

    if [ "$prefix" = "0x0" ]; then
      # Window Mode
      ffcast "-#" $windowid rec $filename
    else
      # Rectangle mode
      ffcast -g $selection rec $filename
    fi

    ${pkgs.mpv}/bin/mpv $filename &
    # xclip -selection clipboard -t video/mp4 -i $filename # does not seem to work
  fi
''
