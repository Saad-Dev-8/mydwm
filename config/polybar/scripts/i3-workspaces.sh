#!/bin/bash
# i3 workspace script for Polybar

# Colors
COLOR_CURRENT="#88c0d0"
COLOR_OTHER="#d8dee9"

# Workspace icons
WS_ICONS=("  " "  " "  " "  " "  " "  " "  " "  " "  " "  ")

# Function to get workspace info from i3
get_workspaces() {
    i3-msg -t get_workspaces | jq -r '.[] | "\(.name)|\(.focused)"'
}

# Function to update and display workspaces
update_workspaces() {
    local workspace_icons=""

    while IFS='|' read -r name focused; do
        ws_num=$(echo "$name" | grep -o '^[0-9]\+')

        # Guard: skip array lookup for non-numeric workspace names
        if [[ "$ws_num" =~ ^[0-9]+$ ]] && (( ws_num >= 1 && ws_num <= ${#WS_ICONS[@]} )); then
            ws_icon="${WS_ICONS[$((ws_num - 1))]}"
        else
            ws_icon=" $name"
        fi

        if [ "$focused" = "true" ]; then
            workspace_icons+="%{F${COLOR_CURRENT}}${ws_icon}%{F-}"
        else
            workspace_icons+="%{F${COLOR_OTHER}}${ws_icon}%{F-}"
        fi

    done < <(get_workspaces | sort -V)

    echo "$workspace_icons"
}

# Main execution
if [ "$1" = "--tail" ]; then
    update_workspaces

    # Reconnecting subscription loop — restarts if the connection drops
    while true; do
        i3-msg -t subscribe -m '[ "workspace" ]' | while read -r _line; do
            update_workspaces
        done
        # Brief pause before reconnecting to avoid busy-looping on repeated failures
        sleep 1
    done
else
    update_workspaces
fi
