#!/usr/bin/env bash

## Author : Aditya Shakya (adi1090x)
## Github : @adi1090x
## Adapted for elogind

# CMDs
uptime="`uptime -p | sed -e 's/up //g'`"

# Options
shutdown='󰐥'
reboot='󰜉'
lock=''
suspend=''
logout='󰍃'

# Rofi CMD
rofi_cmd() {
	rofi -dmenu \
		-p "" \
		-mesg "Uptime: $uptime" \
		-theme "$HOME/.config/rofi/themes/powermenu.rasi"
}

# Pass variables to rofi dmenu
run_rofi() {
	echo -e "$lock\n$suspend\n$logout\n$reboot\n$shutdown" | rofi_cmd
}

# Execute Command with elogind
run_cmd() {
	case $1 in
		--shutdown)
			loginctl poweroff
			;;
		--reboot)
			loginctl reboot
			;;
		--suspend)
			mpc -q pause
			amixer set Master mute
			loginctl suspend
			;;
		--logout)
			case "$DESKTOP_SESSION" in
				openbox)
					openbox --exit
					;;
				bspwm)
					bspc quit
					;;
				dwm)
					pkill dwm
					;;
				i3)
					i3-msg exit
					;;
				plasma)
					qdbus org.kde.ksmserver /KSMServer logout 0 0 0
					;;
                awesome)
                    pkill awesome
                    ;;
				*)
					# Fallback for other WMs
					pgrep -x i3 && i3-msg exit
					pgrep -x dwm && pkill dwm
					pgrep -x bspwm && bspc quit
					;;
			esac
			;;
	esac
}

# Lock command
lock_cmd() {
	if [[ -x '/usr/bin/betterlockscreen' ]]; then
		betterlockscreen -l
	elif [[ -x '/usr/bin/i3lock' ]]; then
		i3lock
	elif [[ -x '/usr/bin/swaylock' ]]; then
		swaylock
	else
		# Fallback - try to use any available locker
		for locker in betterlockscreen i3lock swaylock; do
			if command -v $locker &> /dev/null; then
				$locker
				break
			fi
		done
	fi
}

# Actions
chosen="$(run_rofi)"
case "${chosen}" in
    "${shutdown}")
		run_cmd --shutdown
        ;;
    "${reboot}")
		run_cmd --reboot
        ;;
    "${lock}")
		lock_cmd
        ;;
    "${suspend}")
		run_cmd --suspend
        ;;
    "${logout}")
		run_cmd --logout
        ;;
esac
