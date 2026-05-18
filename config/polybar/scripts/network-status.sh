#!/bin/bash
# ~/.config/polybar/scripts/network-status.sh
# Polybar network status module with WiFi and Ethernet support.
# Requires: nmcli (NetworkManager), Nerd Fonts patched font
# Polybar module must use: tail = true

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

A Polybar network status script with WiFi and Ethernet support.
Displays connection state, SSID (WiFi), animated spinner during transitions,
and signal strength icons. Reacts instantly to NetworkManager events.

Requirements:
  - nmcli        (NetworkManager CLI, ships with NetworkManager)
  - Nerd Fonts   (any patched font with Material Design icons)
  - Polybar      (module must be configured with tail = true)

Options:
  -w, --wifi     IFACE   WiFi interface to monitor      (default: auto-detect)
  -e, --eth      IFACE   Ethernet interface to monitor  (default: auto-detect)
  --no-wifi              Disable WiFi monitoring
  --no-eth               Disable Ethernet monitoring
  --ssid-len     N       Max SSID display length        (default: 20)
  --spinner-fps  N       Spinner frames per second      (default: ~6, min 1)
  --signal-refresh N     Signal refresh interval (sec)  (default: 30)
  -h, --help             Show this help message

Polybar module example:
  [module/network]
  type             = custom/script
  exec             = ~/.config/polybar/scripts/network-status.sh
  tail             = true
  click-left       = networkmanager_dmenu   # optional

Colors (edit at the top of this script):
  C_WIFI     Connected WiFi colour   (default: Nord blue  #88c0d0)
  C_ETH      Connected Eth colour    (default: Nord green #a3be8c)
  C_SPINNER  Transition colour       (default: Nord amber #ebcb8b)
  C_ERROR    Disconnected colour     (default: Nord red   #bf616a)

EOF
    exit 0
}

WIFI_IFACE=""        # auto-detected if empty
ETH_IFACE=""         # auto-detected if empty
ENABLE_WIFI=true
ENABLE_ETH=true
MAX_SSID_LEN=20
SPINNER_INTERVAL=0.15
SIGNAL_REFRESH=30

# Colours
C_WIFI="#88c0d0"
C_ETH="#a3be8c"
C_SPINNER="#ebcb8b"
C_ERROR="#bf616a"
C_RESET="%{F-}"

# Arc spinner frames
SPINNER_FRAMES=("󰪞" "󰪟" "󰪠" "󰪡" "󰪢" "󰪣" "󰪤" "󰪥")
SPINNER_COUNT=${#SPINNER_FRAMES[@]}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)        usage ;;
        -w|--wifi)        WIFI_IFACE="$2";        shift 2 ;;
        -e|--eth)         ETH_IFACE="$2";         shift 2 ;;
        --no-wifi)        ENABLE_WIFI=false;       shift   ;;
        --no-eth)         ENABLE_ETH=false;        shift   ;;
        --ssid-len)       MAX_SSID_LEN="$2";       shift 2 ;;
        --spinner-fps)    SPINNER_INTERVAL=$(echo "scale=2; 1/$2" | bc); shift 2 ;;
        --signal-refresh) SIGNAL_REFRESH="$2";     shift 2 ;;
        *) echo "Unknown option: $1" >&2; usage ;;
    esac
done

if $ENABLE_WIFI; then
    if [ -z "$WIFI_IFACE" ] || [ ! -d "/sys/class/net/$WIFI_IFACE" ]; then
        WIFI_IFACE=$(ls /sys/class/net/ 2>/dev/null | grep -E '^wl' | head -1)
    fi
    if [ -z "$WIFI_IFACE" ] || [ ! -d "/sys/class/net/$WIFI_IFACE" ]; then
        ENABLE_WIFI=false
    fi
fi

if $ENABLE_ETH; then
    if [ -z "$ETH_IFACE" ] || [ ! -d "/sys/class/net/$ETH_IFACE" ]; then
        ETH_IFACE=$(ls /sys/class/net/ 2>/dev/null | grep -E '^(en|eth)' | head -1)
    fi
    if [ -z "$ETH_IFACE" ] || [ ! -d "/sys/class/net/$ETH_IFACE" ]; then
        ENABLE_ETH=false
    fi
fi

if ! $ENABLE_WIFI && ! $ENABLE_ETH; then
    echo "%{F${C_ERROR}}󰲛 No Network%{F-}"
    exit 1
fi

get_wifi_info() {
    local line
    line=$(nmcli -t -f SSID,SIGNAL,ACTIVE device wifi list ifname "$WIFI_IFACE" 2>/dev/null \
        | grep ':yes$' | head -1)
    if [ -n "$line" ]; then
        local ssid signal
        ssid=$(echo "$line"   | rev | cut -d: -f3- | rev)
        signal=$(echo "$line" | rev | cut -d: -f2  | rev)
        [[ "$signal" =~ ^[0-9]+$ ]] || signal=50
        echo "${ssid}:::${signal}"
    fi
}

get_eth_speed() {
    # Returns link speed in Mbps from sysfs, or empty if unavailable
    local speed
    speed=$(cat "/sys/class/net/${ETH_IFACE}/speed" 2>/dev/null)
    [[ "$speed" =~ ^[0-9]+$ ]] && [ "$speed" -gt 0 ] && echo "${speed}" || echo ""
}

signal_icon() {
    local s="$1"
    if   [ "$s" -ge 80 ]; then echo "󰤨"
    elif [ "$s" -ge 60 ]; then echo "󰤥"
    elif [ "$s" -ge 40 ]; then echo "󰤢"
    elif [ "$s" -ge 20 ]; then echo "󰤟"
    else                        echo "󰤯"
    fi
}

LAST_WIFI_LABEL=""
LAST_ETH_LABEL=""

render_wifi() {
    local info ssid signal icon
    info=$(get_wifi_info)
    if [ -n "$info" ]; then
        ssid="${info%:::*}"
        signal="${info##*:::}"
    else
        ssid=$(nmcli -t -f NAME,DEVICE con show --active 2>/dev/null \
            | grep ":${WIFI_IFACE}$" | cut -d: -f1 | head -1)
        signal=50
    fi

    if [ -z "$ssid" ]; then
        sleep 0.5
        info=$(get_wifi_info)
        if [ -n "$info" ]; then
            ssid="${info%:::*}"
            signal="${info##*:::}"
        fi
    fi

    [ -z "$ssid" ] && return

    [ "${#ssid}" -gt "$MAX_SSID_LEN" ] && ssid="${ssid:0:$MAX_SSID_LEN}…"

    local new="${ssid}:${signal}"
    [ "$new" = "$LAST_WIFI_LABEL" ] && return
    LAST_WIFI_LABEL="$new"

    icon=$(signal_icon "$signal")
    print_output "%{F${C_WIFI}}${icon} ${ssid}${C_RESET}"
}

render_eth() {
    local speed label
    speed=$(get_eth_speed)
    if [ -n "$speed" ]; then
        if   [ "$speed" -ge 1000 ]; then label="$(( speed / 1000 ))G"
        else                             label="${speed}M"
        fi
        label=" ${label}"
    else
        label=""  # connected but speed unknown — just show icon
    fi

    local new="eth${label}"
    [ "$new" = "$LAST_ETH_LABEL" ] && return
    LAST_ETH_LABEL="$new"

    print_output "%{F${C_ETH}}󰈀${label}${C_RESET}"
}

# Tracks last printed line per interface so we can combine WiFi + Ethernet
# into a single bar output without one overwriting the other.
LAST_WIFI_OUT=""
LAST_ETH_OUT=""

print_output() {
    # Called with the output for whichever interface just changed.
    # Combines both into one line separated by a space if both are active.
    local new_out="$1"

    # Determine which interface this call is for by checking the colour prefix
    if [[ "$new_out" == *"${C_WIFI}"* ]] || [[ "$new_out" == *"${C_ERROR}"* && "$_RENDER_CTX" == "wifi" ]]; then
        LAST_WIFI_OUT="$new_out"
    else
        LAST_ETH_OUT="$new_out"
    fi

    local combined=""
    [ -n "$LAST_ETH_OUT"  ] && combined="$LAST_ETH_OUT"
    if [ -n "$LAST_WIFI_OUT" ]; then
        [ -n "$combined" ] && combined="${combined}  ${LAST_WIFI_OUT}" || combined="$LAST_WIFI_OUT"
    fi
    echo "$combined"
}

# Simpler direct-output helpers used by handle_state
emit_wifi() { _RENDER_CTX="wifi"; LAST_WIFI_OUT="$1"; _flush_output; }
emit_eth()  { _RENDER_CTX="eth";  LAST_ETH_OUT="$1";  _flush_output; }

_flush_output() {
    local combined=""
    [ -n "$LAST_ETH_OUT"  ] && combined="$LAST_ETH_OUT"
    if [ -n "$LAST_WIFI_OUT" ]; then
        [ -n "$combined" ] && combined="${combined}  ${LAST_WIFI_OUT}" || combined="$LAST_WIFI_OUT"
    fi
    echo "$combined"
}

SPINNER_PID=""
SPINNER_FLAG="/tmp/polybar-network-spinner-$$"

kill_spinner() {
    rm -f "$SPINNER_FLAG"
    if [ -n "$SPINNER_PID" ] && kill -0 "$SPINNER_PID" 2>/dev/null; then
        kill "$SPINNER_PID" 2>/dev/null
        wait "$SPINNER_PID" 2>/dev/null
    fi
    SPINNER_PID=""
}

start_spinner() {
    kill_spinner
    touch "$SPINNER_FLAG"
    local label="$1"
    local iface="$2"   # "wifi" or "eth" — controls which slot gets the spinner
    local flag="$SPINNER_FLAG"
    (
        local frame=0
        while [ -f "$flag" ]; do
            local out="%{F${C_SPINNER}}${SPINNER_FRAMES[$frame]} ${label}${C_RESET}"
            if [ "$iface" = "eth" ]; then
                LAST_ETH_OUT="$out"
            else
                LAST_WIFI_OUT="$out"
            fi
            _flush_output
            frame=$(( (frame + 1) % SPINNER_COUNT ))
            sleep "$SPINNER_INTERVAL"
        done
    ) &
    SPINNER_PID=$!
}

REFRESH_PID=""

start_signal_refresh() {
    (
        while true; do
            sleep "$SIGNAL_REFRESH"
            if [ -z "$SPINNER_PID" ]; then
                [ -n "$LAST_WIFI_LABEL" ] && { LAST_WIFI_LABEL=""; render_wifi_direct; }
                [ -n "$LAST_ETH_LABEL"  ] && render_eth_direct
            fi
        done
    ) &
    REFRESH_PID=$!
}

render_wifi_direct() {
    local info ssid signal icon
    info=$(get_wifi_info)
    [ -z "$info" ] && return
    ssid="${info%:::*}"; signal="${info##*:::}"
    [ "${#ssid}" -gt "$MAX_SSID_LEN" ] && ssid="${ssid:0:$MAX_SSID_LEN}…"
    local new="${ssid}:${signal}"
    [ "$new" = "$LAST_WIFI_LABEL" ] && return
    LAST_WIFI_LABEL="$new"
    icon=$(signal_icon "$signal")
    emit_wifi "%{F${C_WIFI}}${icon} ${ssid}${C_RESET}"
}

render_eth_direct() {
    local speed label
    speed=$(get_eth_speed)
    if [ -n "$speed" ]; then
        [ "$speed" -ge 1000 ] && label="$(( speed / 1000 ))G" || label="${speed}M"
        label=" ${label}"
    else
        label=""
    fi
    local new="eth${label}"
    [ "$new" = "$LAST_ETH_LABEL" ] && return
    LAST_ETH_LABEL="$new"
    emit_eth "%{F${C_ETH}}󰈀${label}${C_RESET}"
}

parse_event_state() {
    local iface="$1" event="$2"
    echo "$event" | sed "s/^${iface}: //" | awk '{print $1}'
}

handle_wifi_state() {
    local state="$1"
    case "$state" in
        connecting|authenticating|associating|prepare|config|ip-config|ip-check|secondaries|need-auth)
            start_spinner "Connecting" "wifi"
            ;;
        disconnecting|deactivating)
            start_spinner "Disconnecting" "wifi"
            ;;
        connected)
            kill_spinner
            LAST_WIFI_LABEL=""
            render_wifi_direct
            ;;
        disconnected)
            kill_spinner
            LAST_WIFI_LABEL=""
            emit_wifi "%{F${C_ERROR}}󰤮 Disconnected${C_RESET}"
            ;;
        unavailable|unmanaged)
            kill_spinner
            LAST_WIFI_LABEL=""
            emit_wifi "%{F${C_ERROR}}󰤮 Unavailable${C_RESET}"
            ;;
    esac
}

handle_eth_state() {
    local state="$1"
    case "$state" in
        connecting|authenticating|prepare|config|ip-config|ip-check|secondaries|need-auth)
            start_spinner "Connecting" "eth"
            ;;
        disconnecting|deactivating)
            start_spinner "Disconnecting" "eth"
            ;;
        connected)
            kill_spinner
            LAST_ETH_LABEL=""
            render_eth_direct
            ;;
        disconnected|unavailable|unmanaged)
            kill_spinner
            LAST_ETH_LABEL=""
            LAST_ETH_OUT=""
            # Don't emit anything — ethernet absence is silent if WiFi is showing
            $ENABLE_WIFI || emit_eth "%{F${C_ERROR}}󰈀 Disconnected${C_RESET}"
            ;;
    esac
}

MONITOR_PID=""

cleanup() {
    kill_spinner
    [ -n "$REFRESH_PID"  ] && kill "$REFRESH_PID"  2>/dev/null
    [ -n "$MONITOR_PID"  ] && kill "$MONITOR_PID"  2>/dev/null
    wait 2>/dev/null
    exit 0
}

trap cleanup EXIT INT TERM HUP

if $ENABLE_ETH; then
    ETH_STATE=$(nmcli -t -f DEVICE,STATE device status 2>/dev/null \
        | grep "^${ETH_IFACE}:" | cut -d: -f2)
    handle_eth_state "$ETH_STATE"
fi

if $ENABLE_WIFI; then
    WIFI_STATE=$(nmcli -t -f DEVICE,STATE device status 2>/dev/null \
        | grep "^${WIFI_IFACE}:" | cut -d: -f2)
    handle_wifi_state "$WIFI_STATE"
fi

start_signal_refresh

while true; do
    coproc MONITOR { nmcli monitor 2>/dev/null; }
    MONITOR_PID=$!

    while IFS= read -r event <&"${MONITOR[0]}"; do
        if $ENABLE_WIFI && [[ "$event" == "${WIFI_IFACE}:"* ]]; then
            handle_wifi_state "$(parse_event_state "$WIFI_IFACE" "$event")"
        elif $ENABLE_ETH && [[ "$event" == "${ETH_IFACE}:"* ]]; then
            handle_eth_state "$(parse_event_state "$ETH_IFACE" "$event")"
        fi
    done

    # Monitor pipe closed — NM restarted or crashed
    kill_spinner
    LAST_WIFI_LABEL=""
    LAST_ETH_LABEL=""
    echo "%{F${C_ERROR}}󰲛 NM Error${C_RESET}"
    sleep 2

    # Re-query both interfaces after NM recovers
    if $ENABLE_ETH; then
        ETH_STATE=$(nmcli -t -f DEVICE,STATE device status 2>/dev/null \
            | grep "^${ETH_IFACE}:" | cut -d: -f2)
        handle_eth_state "${ETH_STATE:-disconnected}"
    fi
    if $ENABLE_WIFI; then
        WIFI_STATE=$(nmcli -t -f DEVICE,STATE device status 2>/dev/null \
            | grep "^${WIFI_IFACE}:" | cut -d: -f2)
        handle_wifi_state "${WIFI_STATE:-disconnected}"
    fi
done
