{ lib, config, pkgs, hyprland, nixpkgs-unstable, walker, ... }:
with lib;
let
  # Shorter name to access final settings a 
  # user of hello.nix module HAS ACTUALLY SET.
  # cfg is a typical convention.
  cfg = config.custom.hyprland;

  swayidleScript = pkgs.writeShellScript "sleep.sh" "echo foo > /home/christopher/testexec.txt";
in
{

  imports = [
    ./hyprpaper.nix
    ./media/playerctl.nix
    /* hyprland.nixosModules.default */
  ];

  # Declare what settings a user of this "hello.nix" module CAN SET.
  options.custom.hyprland = {
    enable = mkEnableOption "Enable hyprland, waybar, light, hyprpaper";
  };

  config = mkIf cfg.enable {
    # Add hyprland cachix 
    nix.settings = {
      substituters = [ "https://hyprland.cachix.org" ];
      trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
    };
    # Hyprland
    programs.hyprland = {
      enable = true;
      withUWSM = true;
      #package = nixpkgs-unstable.legacyPackages.${pkgs.system}.hyprland;
      #package = hyprland.packages.${pkgs.system}.hyprland;
    };

    # Light daemon support for backlight
    programs.light.enable = true;

    # Enable Wayland Ozone for Electron apps
    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    users.users.christopher = {
      # Add user to group for enabling brightness setting to user 
      extraGroups = [ "video" ];
      packages = with pkgs; [
        alacritty # Terminal emulator
        grimblast # Screenshot
      ];
    };

    # Enable playerctl
    custom.media.playerctl.enable = true;

    # Fonts for hyprland theme
    fonts.packages = with pkgs; ([
      font-awesome
    ] ++ (with nerd-fonts; [ fira-code agave hack droid-sans-mono ]));

    # Enable hyprpaper
    custom.hyprpaper.enable = true;

    # Set display targetwallpapers
    custom.hyprpaper.target = [ "DP-1" "DP-2" "HDMI-A-1" ];

    # Set wallpaper
    custom.hyprpaper.wallpaperFile = "${../assets/wallpapers/LatourdeCarol.jpg}";

    # Configure everything with homemanager
    home-manager.users.christopher = { ... }: {
      imports = [
        walker.homeManagerModules.default
      ];

      programs.walker = {
        enable = true;
        runAsService = true;
        package = pkgs.walker;
      };
      services.hypridle = {
        enable = true;

        settings = {
          general = {
            after_sleep_cmd = "hyprctl dispatch dpms on";
            ignore_dbus_inhibit = false;
            lock_cmd = "${pkgs.hyprlock}/bin/hyprlock";
          };

          listener = [
            {
              timeout = 900;
              on-timeout = "${pkgs.hyprlock}/bin/hyprlock";
            }
          ];
        };

      };

      home.pointerCursor = {
        gtk.enable = true;
        # x11.enable = true;
        package = pkgs.phinger-cursors;
        name = "phinger-cursors-light";
        size = 32;
      };

      gtk = {
        enable = true;
        theme = {
          package = pkgs.flat-remix-gtk;
          name = "Flat-Remix-GTK-Grey-Darkest";
        };

        iconTheme = {
          package = pkgs.adwaita-icon-theme;
          name = "Adwaita";
        };

        font = {
          name = "Fira Sans";
          size = 11;
        };
      };

      # Notification daemon
      services.dunst.enable = true;

      wayland.windowManager.hyprland.enable = true;

      programs.hyprlock = {
        enable = true;
        settings = {
          # inspiration from https://github.com/justinmdickey/publicdots/blob/main/.config/hypr/hyprlock.conf
          background = [
            {
              path = "screenshot";
              blur_passes = 3; # 0 disables blurring
              blur_size = 8;
              noise = 1.17e-2;
            }
          ];

          label = map
            (m:
              {
                monitor = m;
                text = "$TIME";
                color = "rgba(242, 243, 244, 0.75)";
                font_size = 95;
                font_family = "JetBrains Mono";
                position = "0, 300";
                halign = "center";
                valign = "center";
              }) [ "DP-2" "HDMI-A-1" ] ++ # Show time left/right monitors
          [{

            monitor = "DP-1";
            text = ''cmd[update:1000] echo $(date +"%A, %B %d")'';
            color = "rgba(242, 243, 244, 0.75)";
            font_size = 22;
            font_family = "JetBrains Mono";
            position = "0, 200";
            halign = "center";
            valign = "center";

          }]; # Password on center

          image = {
            path = "${../assets/profile/duck.jpg}";
            position = "0, 50";
            halign = "center";
            valign = "center";
          };

          input-field = {
            monitor = "DP-1";
            size = "200,50";
            outline_thickness = 2;
            dots_size = 0.2; # Scale of input-field height, 0.2 - 0.8
            dots_spacing = 0.35; # Scale of dots' absolute size, 0.0 - 1.0
            dots_center = true;
            outer_color = "rgba(0, 0, 0, 0)";
            inner_color = "rgba(0, 0, 0, 0.2)";
            font_color = "rgb(111, 45, 104)";
            fade_on_empty = false;
            rounding = -1;
            check_color = "rgb(30, 107, 204)";
            placeholder_text = ''<i><span foreground="##cdd6f4">Input Password...</span></i>'';
            hide_input = false;
            position = "0, -150";
            halign = "center";
            valign = "center";
          };
        };
      };

      # Use Hyprland from Unstable
      # wayland.windowManager.hyprland.package = nixpkgs-unstable.legacyPackages.${pkgs.system}.hyprland;

      wayland.windowManager.hyprland.extraConfig =
        let
          brightnessIncreaseStep = "5";
          brightnessDecreaseStep = "5";
          audioDecreasePercent = "5";
          audioIncreasePercent = "5";

        in
        ''
                    $mod = SUPER
                    bind=$mod,F,fullscreen
                    bind=$mod,M, exec, ${pkgs.hyprlock}/bin/hyprlock
                    bind = , Print, exec, grimblast copy area

                    # workspaces
                    # binds $mod + [shift +] {1..10} to [move to] workspace {1..10}
                    ${builtins.concatStringsSep "\n" (builtins.genList (
                        x: let
                          ws = let
                            c = (x + 1) / 10;
                          in
                            builtins.toString (x + 1 - (c * 10));
                        in ''
                          bind = $mod, ${ws}, workspace, ${toString (x + 1)}
                          bind = $mod SHIFT, ${ws}, movetoworkspace, ${toString (x + 1)}
                        ''
                      )
                      10)}

                      autogenerated = 0 # remove this line to remove the warning
                      # See https://wiki.hyprland.org/Configuring/Monitors/
                      ${
                        let
                          rotate = false;
                          leftMostWidth = if rotate then 1080 else 1920;
                          leftMostHeight = if rotate then 1920 else 1080;
                          leftMostTransform = if rotate then 3 else 0;
                        in
          '' 
                      monitor=HDMI-A-1,1920x1080,0x0,1,transform,${toString leftMostTransform}
                      monitor=DP-1,3840x2160,${toString leftMostWidth}x0,1.5
                      monitor=DP-2,3840x2160,${toString (2560+leftMostWidth)}x0,1.5
          ''
              }

                      # See https://wiki.hyprland.org/Configuring/Keywords/ for more

                      # Execute your favorite apps at launch

                      # Bar
                      ${if config.custom.hyprpaper.enable then "exec-once = hyprpaper-withconfig" else ""} 

                      # Polkit authentication agent
                      exec-once = ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1
            
                      # Source a file (multi-file configs)
                      # source = ~/.config/hypr/myColors.conf

                      # For all categories, see https://wiki.hyprland.org/Configuring/Variables/
                      input {
                          kb_layout = de
                          kb_variant =
                          kb_model =
                          kb_options =
                          kb_rules =

                          follow_mouse = 1

                          touchpad {
                              natural_scroll = yes
                          }

                          sensitivity = 0 # -1.0 - 1.0, 0 means no modification.
                      }

                      general {
                          # See https://wiki.hyprland.org/Configuring/Variables/ for more

                          gaps_in = 1
                          gaps_out = 1
                          border_size = 2
                          col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
                          col.inactive_border = rgba(595959aa)

                          layout = dwindle

                          resize_on_border = true
                      }

                      animations {
                          enabled = yes

                          # Some default animations, see https://wiki.hyprland.org/Configuring/Animations/ for more

                          bezier = myBezier, 0.05, 0.9, 0.1, 1.05

                          animation = windows, 1, 7, myBezier
                          animation = windowsOut, 1, 7, default, popin 80%
                          animation = border, 1, 10, default
                          animation = fade, 1, 7, default
                          animation = workspaces, 1, 6, default
                      }

                      cursor {
                        enable_hyprcursor = false
                      }
                      env = HYPRCURSOR_THEME,MyCursor
                      env = HYPRCURSOR_SIZE,32

                      dwindle {
                          # See https://wiki.hyprland.org/Configuring/Dwindle-Layout/ for more
                          pseudotile = yes # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
                          preserve_split = yes # you probably want this
                      }

                      master {
                          # See https://wiki.hyprland.org/Configuring/Master-Layout/ for more
                          new_status = "master"
                      }

                      gestures {
                          # See https://wiki.hyprland.org/Configuring/Variables/ for more
                          workspace_swipe = on
                      }

                      # Example per-device config
                      # See https://wiki.hyprland.org/Configuring/Keywords/#executing for more

                      $mainMod = SUPER

                      # Example binds, see https://wiki.hyprland.org/Configuring/Binds/ for more
                      bind = $mainMod, Q, exec, alacritty
                      bind = $mainMod SHIFT, Q, killactive,
                      bind = $mainMod SHIFT ALT, Q, exit,
                      bind = $mainMod, E, exec, nautilus
                      bind = $mainMod, space, togglefloating,
                      bind = $mainMod, D, exec, ${pkgs.walker}/bin/walker
                      bind = $mainMod, P, pseudo, # dwindle
                      bind = $mainMod, S, togglesplit, # dwindle

                      # Move focus with mainMod + arrow keys
                      bind = $mainMod,H, movefocus, l
                      bind = $mainMod,L, movefocus, r
                      bind = $mainMod,J, movefocus, u
                      bind = $mainMod,K, movefocus, d

                      # Scroll through existing workspaces with mainMod + scroll
                      bind = $mainMod, mouse_down, workspace, e+1
                      bind = $mainMod, mouse_up, workspace, e-1

                      # Move/resize windows with mainMod + LMB/RMB and dragging
                      bindm = $mainMod, mouse:272, movewindow
                      bindm = $mainMod, mouse:273, resizewindowf

                      # Brightness control
                      bind=,XF86MonBrightnessDown,exec, light -U ${brightnessDecreaseStep}
                      bind=,XF86MonBrightnessUp,exec, light -A ${brightnessIncreaseStep}


                      # Scratchpad
                      bind=$mainMod SHIFT,T,movetoworkspace,special:T
                      bind=$mainMod,T,togglespecialworkspace,T
            
                      # Lower and raise volume with hold 
                      binde=, XF86AudioLowerVolume, exec, wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ ${audioDecreasePercent}%-
                      binde=, XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ ${audioIncreasePercent}%+


                      # Previous/Play-Pause/Forward on AltGr+(F7/F8/F9)
                      binde=Mod5, F7, exec, playerctl previous
                      binde=Mod5, F8, exec, playerctl play-pause
                      binde=Mod5, F9, exec, playerctl next

                      # Mute default output on Fn+F12
                      binde=Mod5, F12, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        '';
      systemd.user.services.waybar.Unit.After = lib.mkForce "graphical-session.target";
      programs.waybar = {
        enable = true;
        systemd.enable = true;
        style = ''
          * {
            /* `otf-font-awesome` is required to be installed for icons */
            border: #333333;
            border-radius: 10px;
            /* border-radius: 50%; */
            font-family: "Hack Nerd Font", FontAwesome, Roboto, Helvetica, Arial, sans-serif;
            font-size: 16px;
            /* background-color: #2B3031; */
            background-color: rgba(43, 48, 59, .0);
          }

          tooltip * {
            background-color: black;
          }

          window#waybar {
            /* border-bottom: 3px solid rgba(100, 114, 125, 0.5); */
            color: #FFFFFF;
            transition-property: background-color;
            transition-duration: .5s;
          }

          window#waybar.hidden {
            opacity: 0.2;
          }

          /*
          window#waybar.empty {
              background-color: transparent;
          }
          window#waybar.solo {
              background-color: #FFFFFF;
          }
          */

          window#waybar.termite {
            background-color: #3F3F3F;
          }

          window#waybar.firefox {
            background-color: #000000;
            border: none;
          }

          button {
            /* Use box-shadow instead of border so the text isn't offset */
            box-shadow: inset 0 -3px transparent;
            /* Avoid rounded borders under each button name */
            border: none;
            border-radius: 0;
          }

          /* https://github.com/Alexays/Waybar/wiki/FAQ#the-workspace-buttons-have-a-strange-hover-effect */
          button:hover {
            background: inherit;
          }

          #workspaces button {
            padding-left: 5px;
            padding-right: 5px;

            padding-top: 0;
            padding-bottom: 0;

            border-radius: 10px;

            background-color: transparent;
            color: #ffffff;

            margin-left: 1.5px;
            margin-right: 1.5px;
          }

          #workspaces button:hover {
            background-color: #333333;
          }

          #workspaces button.focused {
            background-color: #bbccdd;
          }

          #workspaces button.active {
            background-color: #bbccdd;
            color: #333333;
          }

          #workspaces button.urgent {
            background-color:#ffa000;
          }

          #window,
          #workspaces {
            margin: 0 4px;
          }

          #workspaces,
          #workspaces button,
          #workspaces button:hover,
          #workspaces button.focused,
          #workspaces button.urgent {
            /* padding-right: 0px;
              padding: 0px 6px;
              padding-left: 2px; */
          }

          #mode {
            background-color: #64727D;
            border-bottom: 3px solid #ffffff;
          }

          #clock,
          #battery,
          #cpu,
          #memory,
          #disk,
          #temperature,
          #backlight,
          #network,
          #pulseaudio,
          #wireplumber,
          #custom-media,
          #tray,
          #mode,
          #idle_inhibitor,
          #scratchpad,
          #custom-power,
          #mpd {
            padding: 0px 9px;
            padding-right: 13px;
            margin: 3px 3px;
            margin-bottom: 0px;
            color: #333333;
          }

          /* If workspaces is the leftmost module, omit left margin */
          .modules-left>widget:first-child>#workspaces {
            margin-left: 0;
          }

          /* If workspaces is the rightmost module, omit right margin */
          .modules-right>widget:last-child>#workspaces {
            margin-right: 0;
          }

          #clock {
            background-color: #bbccdd;
          }

          #battery {
            background-color: #bbccdd;
            color: #333333;
          }

          #battery.charging,
          #battery.plugged {
            color: #ffffff;
            background-color: #26A65B;
          }

          @keyframes blink {
            to {
              background-color: #ffffff;
              color: #000000;
            }
          }

          #battery.critical:not(.charging) {
            background-color: #f53c3c;
            color: #ffffff;
            animation-name: blink;
            animation-duration: 0.5s;
            animation-timing-function: linear;
            animation-iteration-count: infinite;
            animation-direction: alternate;
          }

          label:focus {
            background-color: #000000;
          }

          #cpu {
            background-color: #bbccdd;
            color: #000000;
          }

          #memory {
            background-color: #bbccdd;
          }

          #disk {
            background-color: #bbccdd;
          }

          #backlight {
            background-color: #bbccdd;
          }

          #network {
            background-color: #bbccdd;
          }

          #network.disconnected {
            background-color: #f53c3c;
          }

          #pulseaudio {
            background-color: #bbccdd;
          }

          #pulseaudio.muted {
            background-color: #bbccdd;
          }

          #wireplumber {
            background-color: #bbccdd;
          }

          #wireplumber.muted {
            background-color: #f53c3c;
          }

          #custom-media {
            background-color: #66cc99;
            color: #2a5c45;
            min-width: 100px;
          }

          #custom-media.custom-spotify {
            background-color: #66cc99;
          }

          #custom-media.custom-vlc {
            background-color: #ffa000;
          }

          #temperature {
            background-color: #bbccdd;
          }

          #temperature.critical {
            background-color: #eb4d4b;
          }

          #tray {
            background-color: #bbccdd;
          }

          #tray {
            background-color: #bbccdd;
          }

          #custom-power {
            background-color: #BBCCDD;
            padding-right: 13px;
          }

          #tray>.passive {
            -gtk-icon-effect: dim;
          }

          #tray>.needs-attention {
            -gtk-icon-effect: highlight;
            background-color: #eb4d4b;
          }

          #idle_inhibitor {
            background-color: #bbccdd;
          }

          #idle_inhibitor.activated {
            background-color: #ecf0f1;
            color: #2d3436;
          }

          #mpd {
            background-color: #bbccdd;
          }

          #mpd.disconnected {
            background-color: #f53c3c;
          }

          #mpd.stopped {
            background-color: #90b1b1;
          }

          #mpd.paused {
            background-color: #51a37a;
          }

          #language {
            background: #bbccdd;
            color: #333333;
            padding: 0 5px;
            margin: 0 5px;
            min-width: 16px;
          }

          #keyboard-state {
            background: #bbccdd;
            color: #333333;
            padding: 0 0px;
            margin: 0 5px;
            min-width: 16px;
          }

          #keyboard-state>label {
            padding: 0 5px;
          }

          #keyboard-state>label.locked {
            background: rgba(0, 0, 0, 0.2);
          }

          #scratchpad {
            background: rgba(0, 0, 0, 0.2);
          }

          #scratchpad.empty {
            background-color: transparent;
          }
        '';
        settings = [{
          layer = "top";
          position = "top";
          margin-left = 10;
          margin-right = 10;
          margin-top = 5;
          margin-bottom = 5;

          modules-left = [ "custom/power" "custom/media" "clock" "cpu" ];
          modules-center = [ "hyprland/workspaces" ];
          modules-right = [ "network" "backlight" "pulseaudio" "battery" "tray" ];


          "hyprland/workspaces" = {
            on-click = "activate";
            format = "{id}";
          };

          "hyprland/window" = {
            "format" = "{title}";
            "max-length" = 50;
            #"rewrite"={
            # "(.*) - Mozilla Firefox": "🌎 $1",
            # "(.*) - vim": " $1",
            # "(.*) - zsh": " [$1]"
            #    }
          };
          "keyboard-state" = {
            "numlock" = true;
            "capslock" = true;
            "format" = "{name} {icon}";
            "format-icons" = {
              "locked" = "";
              "unlocked" = "";
            };
          };

          "tray" = {
            # "icon-size"= 21;
            "spacing" = 10;
          };
          "clock" = {
            "tooltip-format" = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
            "format-alt" = "{:%Y-%m-%d}";
          };
          "temperature" = {
            # "thermal-zone"= 2;
            # "hwmon-path"= "/sys/class/hwmon/hwmon2/temp1_input";
            "critical-threshold" = 80;
            # "format-critical"= "{temperatureC}°C {icon}";
            "format" = "{temperatureC}°C {icon}";
            "format-icons" = [ "" "" "" ];
          };
          "cpu" = {
            "interval" = 5;
            "format" = "{usage}% ";
            "tooltip" = false;
          };
          "backlight" = {
            # "device"= "acpi_video1";
            "format" = "{percent}% {icon}";
            "format-icons" = [ "" "" "" "" "" "" "" "" "" ];
          };
          "battery" = {
            "states" = {
              # "good"= 95;
              "warning" = 30;
              "critical" = 15;
            };
            "format" = "{capacity}% {icon}";
            "format-charging" = "{capacity}% ";
            "format-plugged" = "{capacity}% ";
            "format-alt" = "{time} {icon}";
            # "format-good"= ""; # An empty format will hide the module
            # "format-full"= "";
            "format-icons" = [ "" "" "" "" "" ];
          };
          "battery#bat2" = {
            "bat" = "BAT2";
          };
          "network" = {
            # "interface"= "wlp2*"; # (Optional) To force the use of this interface
            "format-wifi" = ""; #({essid} {signalStrength}%) 
            "format-ethernet" = "{ipaddr}/{cidr} ";
            "tooltip-format-wifi" = "{essid} ({signalStrength}%) ";
            "tooltip-format" = "{ifname} via {gwaddr} ";
            "format-linked" = "{ifname} (No IP) ";
            "format-disconnected" = "Disconnected ⚠";
            "format-alt" = "{ifname}: {ipaddr}/{cidr}";
          };
          "pulseaudio" = {
            # "scroll-step"= 1; # %; can be a float
            "format" = "{volume}% {icon}"; #{format_source}";
            "format-bluetooth" = "{volume}% {icon} 󰂯"; #{format_source}";
            "format-bluetooth-muted" = "󰖁 {icon} 󰂯"; #{format_source}";
            "format-muted" = "󰖁 {format_source}";
            "format-source" = "{volume}% ";
            "format-source-muted" = "";
            "format-icons" = {
              "headphone" = "󰋋";
              "hands-free" = "󱡒";
              "headset" = "󰋎";
              "phone" = "";
              "portable" = "";
              "car" = "";
              "default" = [ "" "" "" ];
            };
            "on-click" = "${pkgs.pavucontrol}/bin/pavucontrol";
          };
          "custom/media" = {
            "format" = "{icon} {}";
            "return-type" = "json";
            "max-length" = 40;
            "format-icons" = {
              "spotify" = "";
              "default" = "🎜";
            };
            "escape" = true;
            "exec" = "$HOME/.config/waybar/mediaplayer.py 2> /dev/null"; # Script in resources folder
            # "exec"= "$HOME/.config/waybar/mediaplayer.py --player spotify 2> /dev/null" # Filter player based on name
          };
          "custom/power" = {
            "format" = "{icon}";
            "format-icons" = ""; # 󰣇
            "exec-on-event" = "true";
            "on-click" = "~/.config/hypr/scripts/sessionMenu.sh";
          };

        }];
      };
    };

    # Without this, hyprlock won't unlock
    security.pam.services.hyprlock = { };
  };
}
