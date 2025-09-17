{pkgs ? import <nixpkgs> {}}: let
  i3draw_workspace = "2:2: draw";
  tablet_display = "HDMI-0";
  aux_display = "DP-0";
in
  pkgs.writeShellScriptBin "turn_tablet_on" ''
    # the following grep checks if a resolution and position is set in the display (aka it is active)
    if xrandr --query | grep -oP '${aux_display} connected .+ \('; then
      position="2560"
      preset="dual_display_tablet_on"
    else
      position="0"
      preset="single_display_tablet_on"
    fi
    xrandr --output ${tablet_display} --mode 1920x1080 --pos "''${position}x1440" --scale 1x1 --rotate normal
    otd applypreset "$preset"
    systemctl restart opentabletdriver --user
    i3-msg "workspace ${i3draw_workspace}; move workspace to output ${tablet_display}"
    i3-msg workspace back_and_forth # go back to the originally focused workspace
    for i in {1..100}; do
      otd applypreset "$preset" && break
      sleep 0.1
    done
    if ! pgrep krita >/dev/null && ! pgrep drawpile >/dev/null; then
      krita --nosplash --template /home/jonboh/.flakes/nixos-config-extra-private/krita/share/templates/Vault/.source/VaultTemplate.kra &
      app="krita"
    elif pgrep krita >/dev/null; then
      app="krita"
    elif pgrep drawpile >/dev/null; then
      app="drawpile"
    fi
    if [ -n "$app" ]; then
      for i in {1..100}; do
        ${pkgs.lib.getExe pkgs.wmctrl} -a "$app" && break
        sleep 0.1
      done
    fi
  ''
