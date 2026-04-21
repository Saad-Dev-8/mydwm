#!/bin/bash
# dwm tags for polybar
# requires: dwm-msg, jq

# Nord colors
COLOR_ACTIVE="#88c0d0"  # active tag
COLOR_EMPTY="#d8dee9"   # inactive tag with windows
COLOR_URGENT="#bf616a"  # urgent

# icons matching your config.h tags[]
TAGS=("" "" "" "" "" "" "" "" "")

print_tags() {
    local selected=$1
    local occupied=$2
    local urgent=$3
    local out=""

    for i in "${!TAGS[@]}"; do
        local bit=$(( 1 << i ))
        local icon="${TAGS[$i]}"

        # hide if empty AND not active AND not urgent
        if (( !(selected & bit) && !(occupied & bit) && !(urgent & bit) )); then
            continue
        fi

        if (( urgent & bit )); then
            out+="%{F${COLOR_URGENT}} ${icon} %{F-}"
        elif (( selected & bit )); then
            out+="%{F${COLOR_ACTIVE}} ${icon} %{F-}"
        else
            out+="%{F${COLOR_EMPTY}} ${icon} %{F-}"
        fi
    done

    echo "$out"
}

# get initial state from get_monitors on startup
init_data=$(dwm-msg get_monitors 2>/dev/null)
init_selected=$(echo "$init_data" | jq '.[0].tag_state.selected')
init_occupied=$(echo "$init_data" | jq '.[0].tag_state.occupied')
init_urgent=$(echo "$init_data"   | jq '.[0].tag_state.urgent')
print_tags "$init_selected" "$init_occupied" "$init_urgent"

# subscribe and read new_state directly from each event
# no extra get_monitors call needed - state is in the event itself
while true; do
    dwm-msg subscribe tag_change_event \
                      client_focus_change_event \
                      focused_title_change_event \
                      layout_change_event \
                      monitor_focus_change_event \
                      focused_state_change_event 2>/dev/null | \
    while IFS= read -r line; do
        # accumulate JSON lines into a full event block
        event+="$line"

        # once we have a complete JSON object parse it
        if echo "$event" | jq -e . >/dev/null 2>&1; then
            # try tag_change_event first (has new_state)
            new_selected=$(echo "$event" | jq -r '.tag_change_event.new_state.selected // empty')
            new_occupied=$(echo "$event" | jq -r '.tag_change_event.new_state.occupied // empty')
            new_urgent=$(echo "$event"   | jq -r '.tag_change_event.new_state.urgent // empty')

            if [ -n "$new_selected" ]; then
                print_tags "$new_selected" "$new_occupied" "$new_urgent"
            else
                # for other events fall back to get_monitors
                data=$(dwm-msg get_monitors 2>/dev/null)
                sel=$(echo "$data" | jq '.[0].tag_state.selected')
                occ=$(echo "$data" | jq '.[0].tag_state.occupied')
                urg=$(echo "$data" | jq '.[0].tag_state.urgent')
                print_tags "$sel" "$occ" "$urg"
            fi
            event=""
        fi
    done
    sleep 1
done
