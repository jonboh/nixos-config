{pkgs ? import <nixpkgs> {}}: let
  i3draw_workspace = "2:2: draw";
  main_display = "DP-2";
  aux_display = "DP-0";
  tablet_display = "HDMI-0";
in
  pkgs.writeShellScriptBin "turn_tablet_off" ''
    xrandr --output ${tablet_display} --off
    if xrandr --query | grep -oP '${aux_display} connected .+ \('; then
      preset="dual_display_tablet_off"
    else
      preset="single_display_tablet_off"
    fi
    otd applypreset "$preset"
    systemctl restart opentabletdriver --user
    i3-msg "workspace ${i3draw_workspace}; move workspace to output ${main_display}"
    i3-msg workspace back_and_forth # go back to the originally focused workspace
    for i in {1..100}; do
      otd applypreset "$preset" && break
      sleep 0.1
    done
  ''
