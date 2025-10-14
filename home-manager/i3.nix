{
  pkgs,
  config,
  ...
}: let
  i3status_file =
    if config.home.computer == "workstation"
    then "i3status.toml"
    else if config.home.computer == "laptop"
    then "i3status-laptop.toml"
    else "i3status.toml";
  primaryDisplay =
    if config.home.computer == "workstation"
    # then "HDMI-0" // hdmi-port (currently on Kanbas13)
    then "DP-2"
    else if config.home.computer == "laptop"
    then "DP-1-6"
    else "";
  secondaryDisplay =
    if config.home.computer == "workstation"
    then "DP-0"
    else if config.home.computer == "laptop"
    then "DP-2"
    else "";
  displayConfiguration =
    if config.home.computer == "workstation"
    then ''
      workspace $term_ws output ${primaryDisplay}
      workspace $draw output ${primaryDisplay}
      workspace $3d output ${primaryDisplay}
      workspace $web output ${secondaryDisplay}
      workspace $comm output ${secondaryDisplay}
      workspace $doc output ${secondaryDisplay}
      workspace $comm output ${secondaryDisplay}
      workspace $media output ${secondaryDisplay}

      workspace $ws4 output ${primaryDisplay}
      workspace $ws10 output ${primaryDisplay}
      workspace $ws5 output ${secondaryDisplay}
    ''
    else "";
  fontSize =
    if config.home.computer != "lab"
    then "12"
    else "9";
in {
  xsession.windowManager = {
    i3 = {
      enable = true;
      config = {
        keybindings = {};
        modes = {};
        bars = [];
        modifier = "Mod4";
        terminal = "kitty";
      };
      extraConfig =
        ''
          set $mod Mod4

          # This font is widely installed, provides lots of unicode glyphs, right-to-left
          # text rendering and scalability on retina/hidpi displays (thanks to pango).
          # font pango:DejaVu Sans Mono 12
          font pango:Inconsolata ${fontSize}

          # Use pactl to adjust volume in PulseAudio.
          set $refresh_i3status killall -SIGUSR1 i3status
          bindsym XF86AudioRaiseVolume exec --no-startup-id wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 2%+ && $refresh_i3status
          bindsym XF86AudioLowerVolume exec --no-startup-id wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 2%- && $refresh_i3status
          bindsym XF86AudioMute exec --no-startup-id wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && $refresh_i3status
          bindsym XF86AudioMicMute exec --no-startup-id wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle && $refresh_i3status
          bindsym XF86AudioPlay exec playerctl play-pause
          bindsym XF86AudioNext exec playerctl next
          bindsym XF86AudioPrev exec playerctl previous

          # Use Mouse+$mod to drag floating windows to their wanted position
          floating_modifier $mod

          # start a terminal
          bindsym $mod+Return exec $TERM
          bindsym $mod+Shift+Return exec "kitty bash"

          # kill focused window
          bindsym $mod+Shift+q kill

          # rofi! menu launcher passwords emojis
          bindsym $mod+d exec --no-startup-id "rofi -show drun"
          bindsym $mod+p exec --no-startup-id "rofi-password-store"
          bindsym $mod+e exec --no-startup-id "rofimoji -f emojis --skin-tone neutral"
          bindsym $mod+Shift+e exec --no-startup-id "rofimoji -f math"
          bindsym $mod+z exec --no-startup-id "zen-mode"
          bindsym $mod+Shift+z exec --no-startup-id "picom-trans -r"

          # notifications
          bindsym $mod+a exec --no-startup-id "dunstctl action"
          bindsym $mod+Shift+a exec --no-startup-id "dunstctl context"
          bindsym $mod+c exec --no-startup-id "dunstctl close"
          bindsym $mod+Shift+c exec --no-startup-id "dunstctl history-pop"

          bindsym $mod+b exec --no-startup-id "librewolf"

          bindsym $mod+s exec ${pkgs.callPackage ../scripts/screenshot.nix {}}/bin/screenshot
          bindsym $mod+Mod1+s exec ${pkgs.callPackage ../scripts/screenshot_full.nix {}}/bin/screenshot
          bindsym $mod+Shift+s exec ${pkgs.callPackage ../scripts/ffcast-screenshot.nix {}}/bin/ffcast-screenshot

          # change focus
          bindsym $mod+Left focus left
          bindsym $mod+Down focus down
          bindsym $mod+Up focus up
          bindsym $mod+Right focus right

          # move focused window
          bindsym $mod+Shift+Left move left 300 px
          bindsym $mod+Shift+Down move down 300 px
          bindsym $mod+Shift+Up move up 300 px
          bindsym $mod+Shift+Right move right 300 px

          # split in horizontal orientation
          bindsym $mod+h split v

          # split in vertical orientation
          bindsym $mod+g split h

          # enter fullscreen mode for the focused container
          bindsym $mod+f fullscreen toggle

          # change container layout (stacked, tabbed, toggle split)
          bindsym $mod+r layout toggle split

          # toggle tiling / floating
          bindsym $mod+Shift+space floating toggle

          # change focus between tiling / floating windows
          bindsym $mod+space focus mode_toggle

          # Turn on/off tablet
          bindsym Mod1+Mod4+Control+Shift+k exec --no-startup-id turn_tablet_on
          bindsym Mod1+Mod4+Control+Shift+j exec --no-startup-id turn_tablet_off

          # Define names for default workspaces for which we configure key bindings later on.
          # We use variables to avoid repeating the names in multiple places.
          # Also we prepend numbers to order the workspaces, these first nubers are stripped by i3bar
          set $ws10 "0:10"
          set $term_ws "1:1: term"
          set $draw "2:2: draw"
          set $3d "3:3: 3d"
          set $ws4 "4:4"
          set $ws5 "9:5"
          set $web "8:6: web"
          set $doc "7:7: doc"
          set $comm "6:8: comm"
          set $media "5:9: media"
        ''
        + displayConfiguration
        + ''
          # switch to workspace
          bindsym $mod+0 workspace number $ws10
          bindsym $mod+1 workspace number $term_ws
          bindsym $mod+2 workspace number $draw
          bindsym $mod+3 workspace number $3d
          bindsym $mod+4 workspace number $ws4
          bindsym $mod+5 workspace number $ws5
          bindsym $mod+6 workspace number $web
          bindsym $mod+7 workspace number $doc
          bindsym $mod+8 workspace number $comm
          bindsym $mod+9 workspace number $media

          # move focused container to workspace
          bindsym $mod+Shift+0 move container to workspace number $ws10
          bindsym $mod+Shift+1 move container to workspace number $term_ws
          bindsym $mod+Shift+2 move container to workspace number $draw
          bindsym $mod+Shift+3 move container to workspace number $3d
          bindsym $mod+Shift+4 move container to workspace number $ws4
          bindsym $mod+Shift+5 move container to workspace number $ws5
          bindsym $mod+Shift+6 move container to workspace number $web
          bindsym $mod+Shift+7 move container to workspace number $doc
          bindsym $mod+Shift+8 move container to workspace number $comm
          bindsym $mod+Shift+9 move container to workspace number $media


          focus_wrapping no
          focus_follows_mouse no
          workspace_auto_back_and_forth no

          # applications workspace assigment
          # run:
          # xprop | rg -i "class"
          # you'll get WM_CLASS(STRING) = <instance> <class>
          # assign [class="Alacritty" instance="Alacritty"] $term_ws
          assign [class="Brave-browser" instance="brave-browser"] $web
          assign [class="firefox" instance="Navigator"] $web
          assign [class="librewolf" instance="Navigator"] $web
          assign [class="Zathura" instance="org.pwmt.zathura"] $doc
          assign [class="(?i)libreoffice-writer$"] $doc
          assign [class="(?i)soffice"] $doc
          assign [class="(?i)libreoffice-calc"] $doc
          assign [class="(?i)libreoffice.*"] $doc
          assign [class="UltiMaker-Cura" instance="UltiMaker-Cura"] $3d
          assign [class="Inkscape" instance="org.inkscape.Inkscape"] $draw
          assign [class="krita" instance="krita"] $draw
          assign [class="drawpile" instance="drawpile"] $draw
          assign [class="Spotify"] $media
          assign [class="feishin"] $media
          assign [class="Supersonic"] $media
          assign [class="Chromium-browser"] $comm
          assign [class="thunderbird" instance="Mail"] $comm
          assign [class="thunderbird" instance="Calendar"] $comm
          assign [class="OrcaSlicer" instance="orca-slicer"] $3d
          assign [class="Gazebo GUI" instance="gz-sim-gui"] $3d
          assign [class="rviz2" instance="rviz2"] $ws10
          # assign [class="prusa-slicer" instance="PrusaSlicer-alpha"] $3d # don't seem to play nicely
          # assign [class="prusa-slicer" instance="PrusaSlicer"] $3d
          # turns out spotify is its own beast dealing with workspace assigment
          for_window [class="Spotify"] move container to workspace $media
          # assign [class="Spotify" instance="spotify"] $media
          for_window [class="firefox"] move container to workspace $web
          for_window [class="librewolf"] move container to workspace $web

          # floating pop up automatically
          for_window [window_role="pop-up"] floating enable
          for_window [window_role="task_dialog"] floating enable
          for_window [class="FloatingTermDialog"] floating enable
          for_window [class="FloatingTermDialog"] resize set 800 400
          for_window [class="Chromium-browser"] floating disable



          # shutdown / restart / suspend...
          set $mode_system System (AllMod) + (l) lock, (r) reboot, (s) shutdown
                  # System (l) lock, (r) reboot, (Ctrl+s) shutdown
                  mode "$mode_system" {
                      # bindsym l exec --no-startup-id $i3lockwall, mode "default"
                          bindsym $mod+Mod1+Ctrl+Shift+l exec --no-startup-id ${pkgs.xlockmore}/bin/xlock -font fixed -delay 10000 -mode flow, mode "default"
                          bindsym $mod+Mod1+Ctrl+Shift+r exec --no-startup-id systemctl reboot, mode "default"
                          bindsym $mod+Mod1+Ctrl+Shift+s exec --no-startup-id systemctl poweroff -i, mode "default"
                          # back to normal
                          bindsym Return mode "default"
                          bindsym Escape mode "default"
                          bindsym Ctrl+c mode "default"
                  }
          set $mode_i3 (r) i3-restart, (c) i3-reload
                  mode "$mode_i3" {
                          # restart i3 inplace (preserves your layout/session, can be used to upgrade i3)
                          bindsym r restart
                          # reload the configuration file
                          bindsym c reload
                          # back to normal
                          bindsym Return mode "default"
                          bindsym Escape mode "default"
                          bindsym Ctrl+c mode "default"
                  }
          set $mode_display (1) 1-display, (2) 2-display, (t) tablet-on, (T) tablet-off, (m) tablet-mirror
                  mode "$mode_display" {
                      bindsym 1 exec --no-startup-id single_display_and_tablet, mode "default"
                      bindsym 2 exec --no-startup-id dual_display_and_tablet, mode "default"
                      bindsym t exec --no-startup-id turn_tablet_on, mode "default"
                      bindsym Shift+t exec --no-startup-id turn_tablet_off, mode "default"
                      bindsym m exec --no-startup-id turn_tablet_on_mirror_main, mode "default"
                      # back to normal
                      bindsym Return mode "default"
                      bindsym Escape mode "default"
                      bindsym Ctrl+c mode "default"
                    }
          bindsym $mod+BackSpace mode "$mode_system"
          bindsym $mod+Tab mode "$mode_i3"
          bindsym $mod+m mode "$mode_display"
          # resize window (you can also use the mouse for that) # Mod1 is Alt
          bindsym $mod+Shift+r mode "resize"
          mode "resize" {
                  # These bindings trigger as soon as you enter the resize mode

                  # Pressing left will shrink the window’s width.
                  # Pressing right will grow the window’s width.
                  # Pressing up will shrink the window’s height.
                  # Pressing down will grow the window’s height.
                  bindsym Left resize shrink width 10 px or 10 ppt
                  bindsym Down resize grow height 10 px or 10 ppt
                  bindsym Up resize shrink height 10 px or 10 ppt
                  bindsym Right resize grow width 10 px or 10 ppt

                  # back to normal
                  bindsym Return mode "default"
                  bindsym Escape mode "default"
                  bindsym Ctrl+c mode "default"
          }
          ##########
          # DESIGN #
          ##########

          ## COLORS
          # special
          set_from_resource $foreground foreground #C6C6C6
          set_from_resource $background background #1C1C1C
          set_from_resource $cursorColor cursorColor #C6C6C6
          # black
          set_from_resource $black1 color0 #303030
          set_from_resource $black2 color8 #444444
          set $trueblack #000000
          # red
          set_from_resource $red1 color1 #d75f5f
          set_from_resource $red2 color9 #d75f5f
          # green
          set_from_resource $green1 color2 #87AF87
          set_from_resource $green2 color10 #87AF87
          # yellow
          set_from_resource $yellow1 color3 #ffd75f
          set_from_resource $yellow2 color11 #ffd75f
          # blue
          set_from_resource $blue1 color4 #87afd7
          set_from_resource $blue2 color12 #87afd7
          # magenta
          set_from_resource $cyan1 color5 #afafd7
          set_from_resource $cyan2 color13 #afafd7
          # cyan
          set_from_resource $cyan1 color6 #afd7ff
          set_from_resource $cyan2 color14 #afd7ff
          # white
          set_from_resource $white1 color7 #4E4E4E
          set_from_resource $white2 color15 #ffffff

          # hide borders
          hide_edge_borders both

          # class                 border  backgr. text    indicator child_border
          client.focused          $background $black1 $white2 $background
          client.focused_inactive $background $black1 $black2 $background
          client.unfocused        $background $background $black2 $background
          client.urgent           $red1 $red1 $white2 $red1 $red1
          client.placeholder      $red1 $red1 $white2 $red1 $red1

          # Start i3bar to display a workspace bar (plus the system information i3status finds out, if available)
          bar {
              # remove the numbers used to reorder the workspaces
              strip_workspace_numbers yes

              status_command i3status-rs $HOME/.flakes/nixos-config/extra_configs/i3/${i3status_file}
              # Disable all tray icons
              tray_output none
              # tray_output primary
              separator_symbol "┃"
              # Disable switching workspaces with scroll
              bindsym button4 nop # scroll up
              bindsym button5 nop # scroll down
              bindsym button6 nop # scroll right
              bindsym button7 nop # scroll left
              colors {
                  background $black1
                  statusline $white2
                  separator $black2

                  #                  border background text
                  focused_workspace  $background $background $red1
                  active_workspace   $black1 $black1 $black2
                  inactive_workspace $background $black1 $foreground
                  urgent_workspace   $red1 $red1 $white2
                  binding_mode       $background $red2 $white2
              }
          }

          exec --no-startup-id dual_display && turn_tablet_off
        '';
    };
  };
}
