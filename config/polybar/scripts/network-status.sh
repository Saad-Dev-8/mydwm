#!/bin/bash
# ~/.config/polybar/scripts/network-status.sh
# Polybar network status script with iwd + dhcpcd + Ethernet + VPN support.

usage() {
  cat << EOF
Usage: $(basename "$0") [OPTIONS]

Polybar network status module.

Options:
  -w, --wifi       IFACE   WiFi interface (default: auto-detect)
  -e, --eth        IFACE   Ethernet interface (default: auto-detect)
  --no-wifi                Disable WiFi monitoring
  --no-eth                 Disable Ethernet monitoring
  --show-ip                Show local IPv4 address alongside interface status
  --show-vpn               Show active VPN/Tunnel interface indicator
  --ssid-len       N       Max SSID display length (default: 20)
  --spinner-fps    N       Spinner frames per second (default: ~6)
  --poll-interval  N       Polling interval in seconds (default: 1.0)
  -h, --help               Show this help message
EOF
  exit 0
}

WIFI_IFACE=""
ETH_IFACE=""
ENABLE_WIFI=true
ENABLE_ETH=true
SHOW_IP=false
SHOW_VPN=false
MAX_SSID_LEN=20

SPINNER_INTERVAL=0.15
SIGNAL_REFRESH=30
POLL_INTERVAL=1.0

POLYBAR_CONFIG="$HOME/.config/polybar/config.ini"

read_color() {
  grep -i "^$1[[:space:]]*=" "$POLYBAR_CONFIG" 2>/dev/null | awk -F'=' '{print $2}' | xargs | head -1
}

C_WIFI=$(read_color "accent-alt")
C_ETH=$(read_color "success")
C_SPINNER=$(read_color "info")
C_ERROR=$(read_color "urgent")
C_VPN=$(read_color "warning")

# Fallback Colors (Nord Theme)
C_WIFI="${C_WIFI:-#88c0d0}"
C_ETH="${C_ETH:-#a3be8c}"
C_SPINNER="${C_SPINNER:-#ebcb8b}"
C_ERROR="${C_ERROR:-#bf616a}"
C_VPN="${C_VPN:-#d08770}"
C_RESET="%{F-}"

SPINNER_FRAMES=("󰪞" "󰪟" "󰪠" "󰪡" "󰪢" "󰪣" "󰪤" "󰪥")
SPINNER_COUNT=${#SPINNER_FRAMES[@]}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)         usage ;;
    -w|--wifi)         WIFI_IFACE="$2"; shift 2 ;;
    -e|--eth)          ETH_IFACE="$2"; shift 2 ;;
    --no-wifi)         ENABLE_WIFI=false; shift ;;
    --no-eth)          ENABLE_ETH=false; shift ;;
    --show-ip)         SHOW_IP=true; shift ;;
    --show-vpn)        SHOW_VPN=true; shift ;;
    --ssid-len)        MAX_SSID_LEN="$2"; shift 2 ;;
    --spinner-fps)
      SPINNER_INTERVAL=$(awk -v fps="$2" 'BEGIN{ if(fps<1) fps=1; printf "%.4f", 1/fps }')
      shift 2 ;;
    --poll-interval)   POLL_INTERVAL="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; usage ;;
  esac
done

detect_ifaces() {
  if $ENABLE_WIFI; then
    if [ -z "$WIFI_IFACE" ] || [ ! -d "/sys/class/net/$WIFI_IFACE" ]; then
      WIFI_IFACE=$(ls /sys/class/net 2>/dev/null | grep -E '^wl|^wlan|^wifi' | head -1)
    fi
    [ -z "$WIFI_IFACE" ] && ENABLE_WIFI=false
  fi

  if $ENABLE_ETH; then
    if [ -z "$ETH_IFACE" ] || [ ! -d "/sys/class/net/$ETH_IFACE" ]; then
      ETH_IFACE=$(ls /sys/class/net 2>/dev/null | grep -E '^(en|eth)' | head -1)
    fi
    [ -z "$ETH_IFACE" ] && ENABLE_ETH=false
  fi
}

get_ipv4() {
  local iface="$1"
  ip -o -4 addr show dev "$iface" scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -1
}

is_wifi_blocked() {
  rfkill list wifi 2>/dev/null | grep -q "Soft blocked: yes\|Hard blocked: yes"
}

get_vpn_iface() {
  ip -o link show 2>/dev/null | grep -E ' (wg|tun|tailscale|zero)[0-9]*:' | awk -F': ' '{print $2}' | head -1
}

wifi_parse_state_ssid_signal() {
  local out state ssid rssi pct
  out="$(iwctl station "$WIFI_IFACE" show 2>/dev/null)"

  state=$(echo "$out" | awk -F 'State' '/State/ {print $2}' | xargs | tr '[:upper:]' '[:lower:]')
  ssid=$(echo "$out" | awk -F 'Connected network' '/Connected network/ {print $2}' | xargs)
  rssi=$(echo "$out" | awk -F 'RSSI' '/RSSI/ {print $2}' | awk '{print $1}' | tr -d '[:alpha:]m ')

  if [[ "$rssi" =~ ^-?[0-9]+$ ]]; then
    if [ "$rssi" -le -90 ]; then pct=0
    elif [ "$rssi" -ge -30 ]; then pct=100
    else pct=$(( (rssi + 90) * 100 / 60 ))
    fi
  fi

  echo "${state}::${ssid}::${pct:-}"
}

signal_icon() {
  local s="$1"
  if   [ "$s" -ge 80 ]; then echo "󰤨"
  elif [ "$s" -ge 60 ]; then echo "󰤥"
  elif [ "$s" -ge 40 ]; then echo "󰤢"
  elif [ "$s" -ge 20 ]; then echo "󰤟"
  else                       echo "󰤯"
  fi
}

detect_ifaces

LAST_COMBINED=""
last_poll=0
last_signal_refresh=0
frame=0

# Cached state variables
wifi_status="off" # off, blocked, connecting, connected
eth_status="off"  # off, connecting, connected
wifi_display_text=""
eth_display_text=""

while true; do
  now=$(date +%s)

  # --- HARDWARE POLL CYCLE (Runs only every POLL_INTERVAL seconds) ---
  if (( $(echo "$now - $last_poll >= $POLL_INTERVAL" | awk '{print ($1)}') )); then
    last_poll=$now

    # Check Wi-Fi
    if [ "$ENABLE_WIFI" = true ]; then
      if is_wifi_blocked; then
        wifi_status="blocked"
      else
        parsed="$(wifi_parse_state_ssid_signal)"
        w_state="${parsed%%::*}"
        rest="${parsed#*::}"
        w_ssid="${rest%%::*}"
        w_signal="${rest##*::}"

        case "$w_state" in
          connected)
            wifi_status="connected"
            if [ -z "$w_ssid" ]; then w_ssid="WiFi"; fi
            [ "${#w_ssid}" -gt "$MAX_SSID_LEN" ] && w_ssid="${w_ssid:0:$MAX_SSID_LEN}…"
            [[ "$w_signal" =~ ^[0-9]+$ ]] || w_signal=50
            
            w_ip=""
            $SHOW_IP && w_ip=" ($(get_ipv4 "$WIFI_IFACE"))"
            
            wifi_display_text="%{F${C_WIFI}}$(signal_icon "$w_signal") ${w_ssid}${w_ip}${C_RESET}"
            ;;
          connecting|authenticating|associating|roaming)
            w_ip_check=$(get_ipv4 "$WIFI_IFACE")
            if [ -n "$w_ip_check" ]; then
              wifi_status="connected"
              wifi_display_text="%{F${C_WIFI}}$(signal_icon 50) ${w_ssid:-WiFi}${C_RESET}"
            else
              wifi_status="connecting"
            fi
            ;;
          *)
            wifi_status="off"
            ;;
        esac
      fi
    fi

    # Check Ethernet
    if [ "$ENABLE_ETH" = true ]; then
      eth_ip=$(get_ipv4 "$ETH_IFACE")
      if [ -n "$eth_ip" ]; then
        eth_status="connected"
        speed="$(cat "/sys/class/net/${ETH_IFACE}/speed" 2>/dev/null)"
        label=""
        if [[ "$speed" =~ ^[0-9]+$ ]] && [ "$speed" -gt 0 ]; then
          [ "$speed" -ge 1000 ] && label=" $(( speed / 1000 ))G" || label=" ${speed}M"
        fi
        
        e_ip=""
        $SHOW_IP && e_ip=" (${eth_ip})"

        eth_display_text="%{F${C_ETH}}󰈀${label}${e_ip}${C_RESET}"
      else
        if [ -f "/sys/class/net/${ETH_IFACE}/carrier" ] && [ "$(cat "/sys/class/net/${ETH_IFACE}/carrier" 2>/dev/null)" = "1" ]; then
          eth_status="connecting"
        else
          eth_status="off"
        fi
      fi
    fi
  fi

  # --- UI RENDER CYCLE (Runs every tick) ---
  cur_wifi_out=""
  cur_eth_out=""
  cur_vpn_out=""

  # Format Wi-Fi Frame
  case "$wifi_status" in
    connected)  cur_wifi_out="$wifi_display_text" ;;
    connecting) cur_wifi_out="%{F${C_SPINNER}}${SPINNER_FRAMES[$frame]} Connecting${C_RESET}" ;;
    blocked)    cur_wifi_out="%{F${C_ERROR}}󰀝 Airplane Mode${C_RESET}" ;;
    *)          cur_wifi_out="%{F${C_ERROR}}󰤮 Disconnected${C_RESET}" ;;
  esac

  # Format Ethernet Frame
  case "$eth_status" in
    connected)  cur_eth_out="$eth_display_text" ;;
    connecting) cur_eth_out="%{F${C_SPINNER}}${SPINNER_FRAMES[$frame]} Connecting${C_RESET}" ;;
    *)          cur_eth_out="" ;;
  esac

  # Format VPN Indicator
  if $SHOW_VPN; then
    vpn_iface=$(get_vpn_iface)
    [ -n "$vpn_iface" ] && cur_vpn_out="%{F${C_VPN}}󰦝 ${vpn_iface}${C_RESET}"
  fi

  # Build Output String
  COMBINED=""
  [ -n "$cur_vpn_out" ] && COMBINED="$cur_vpn_out"
  if [ -n "$cur_eth_out" ]; then
    [ -n "$COMBINED" ] && COMBINED="${COMBINED}  ${cur_eth_out}" || COMBINED="$cur_eth_out"
  fi
  if [ -n "$cur_wifi_out" ]; then
    [ -n "$COMBINED" ] && COMBINED="${COMBINED}  ${cur_wifi_out}" || COMBINED="$cur_wifi_out"
  fi

  # Output to Polybar only on change
  if [ "$COMBINED" != "$LAST_COMBINED" ]; then
    echo "$COMBINED"
    LAST_COMBINED="$COMBINED"
  fi

  # Sleep timing logic
  if [ "$wifi_status" = "connecting" ] || [ "$eth_status" = "connecting" ]; then
    sleep "$SPINNER_INTERVAL"
    frame=$(( (frame + 1) % SPINNER_COUNT ))
  else
    sleep "$POLL_INTERVAL"
  fi
done
