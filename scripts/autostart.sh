#!/bin/bash

# Turn off sleep
xset -dmps
xset s off

# Wallpaper
feh --randomize --bg-fill ~/Pictures/Wallpapers/* &

# Compositor
picom -b &

# Notifications
dunst &

# Screenshot tool
flameshot &

# Hide cursor when idle
unclutter --timeout 5 --hide-on-touch &

# Polybar
~/.config/polybar/launch.sh &
