#!/bin/bash
# Launch nmtui in a floating terminal
# Check if kitty is available (your terminal from earlier)
if command -v kitty &> /dev/null; then
    kitty --class=nmtui-floating -e nmtui
elif command -v st &> /dev/null; then
    st -c nmtui-floating -e gazelle
else
    # Fallback to xterm
    xterm -class nmtui-floating -e nmtui
fi
