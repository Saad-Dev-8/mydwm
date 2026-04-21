#!/bin/bash
# Polybar launch script

# Terminate already running bars
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null || pgrep -u $UID -x i3status >/dev/null; do 
    sleep 0.1
done

# Launch Polybar
polybar main &
