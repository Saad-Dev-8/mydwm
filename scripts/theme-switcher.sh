#!/bin/bash
# theme switcher for mydwm
# changes polybar, dunst, rofi, dwm colors
# backups stored in ~/.config/<app>/themes/backup/

DWMDIR="$HOME/Projects/mydwm"
POLYBAR_CONFIG="$HOME/.config/polybar/config.ini"
DUNST_CONFIG="$HOME/.config/dunst/dunstrc"
ROFI_NORD="$HOME/.config/rofi/themes/nord.rasi"
ROFI_SIDE="$HOME/.config/rofi/themes/sidetab-nord.rasi"
CURRENT_FILE="$HOME/.config/themes/.current"

# ──────────────────────────────────────
# output helpers
# ──────────────────────────────────────
info()    { echo -e "\033[0;34m[INFO]\033[0m $1"; }
success() { echo -e "\033[0;32m[OK]\033[0m $1"; }
error()   { echo -e "\033[0;31m[ERROR]\033[0m $1"; exit 1; }

# ──────────────────────────────────────
# spinner wait
# ──────────────────────────────────────
wait_for() {
    local pid=$1
    local msg=$2
    local spinchars='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0

    while kill -0 "$pid" 2>/dev/null; do
        printf "\r\033[0;34m[WAIT]\033[0m %s %s" "$msg" "${spinchars:$i:1}"
        i=$(( (i+1) % ${#spinchars} ))
        sleep 0.1
    done
    printf "\r\033[0;32m[OK]\033[0m %-40s\n" "$msg"
}

# ──────────────────────────────────────
# theme definitions
# format: bg bg-alt bg-dim disabled fg fg-alt accent accent-alt accent-dim urgent warning info success purple teal
# pos:     1  2      3      4        5  6     7      8          9          10     11      12   13      14     15
# ──────────────────────────────────────
theme_nord() {
    echo "#2e3440 #3b4252 #434c5e #4c566a #d8dee9 #eceff4 #5e81ac #88c0d0 #81a1c1 #bf616a #d08770 #ebcb8b #a3be8c #b48ead #8fbcbb"
}
theme_gruvbox() {
    echo "#282828 #3c3836 #504945 #665c54 #ebdbb2 #fbf1c7 #458588 #83a598 #689d6a #cc241d #d65d0e #d79921 #98971a #b16286 #8ec07c"
}
theme_catppuccin() {
    echo "#1e1e2e #181825 #313244 #45475a #cdd6f4 #b4befe #89b4fa #74c7ec #89b4fa #f38ba8 #fab387 #f9e2af #a6e3a1 #cba6f7 #89dceb"
}
theme_tokyonight() {
    echo "#1a1b26 #16161e #2f3549 #3b4261 #c0caf5 #a9b1d6 #7aa2f7 #7dcfff #7aa2f7 #f7768e #ff9e64 #e0af68 #9ece6a #bb9af7 #2ac3de"
}
theme_rosepine() {
    echo "#191724 #1f1d2e #26233a #403d52 #e0def4 #f0f0f3 #c4a7e7 #9ccfd8 #c4a7e7 #eb6f92 #ea9a97 #f6c177 #31748f #c4a7e7 #9ccfd8"
}
theme_breeze() {
    echo "#232629 #2a2e32 #31363b #3b4248 #eff0f1 #ffffff #3daee9 #1d99f3 #3daee9 #da4453 #f67400 #fdbc4b #27ae60 #8e44ad #16a085"
}

# ──────────────────────────────────────
# backup original configs once
# ──────────────────────────────────────
backup_configs() {
    mkdir -p "$HOME/.config/themes"

    local polybar_bak="$HOME/.config/polybar/themes/backup"
    local dunst_bak="$HOME/.config/dunst/themes/backup"
    local rofi_bak="$HOME/.config/rofi/themes/backup"

    if [ ! -f "$polybar_bak/config.ini" ]; then
        mkdir -p "$polybar_bak"
        cp "$POLYBAR_CONFIG" "$polybar_bak/config.ini"
        success "polybar backup created"
    fi
    if [ ! -f "$dunst_bak/dunstrc" ]; then
        mkdir -p "$dunst_bak"
        cp "$DUNST_CONFIG" "$dunst_bak/dunstrc"
        success "dunst backup created"
    fi
    if [ ! -f "$rofi_bak/nord.rasi" ]; then
        mkdir -p "$rofi_bak"
        cp "$ROFI_NORD" "$rofi_bak/nord.rasi"
        cp "$ROFI_SIDE" "$rofi_bak/sidetab-nord.rasi"
        success "rofi backup created"
    fi
}

# ──────────────────────────────────────
# apply polybar
# ──────────────────────────────────────
apply_polybar() {
    local bg=$1 bg_alt=$2 bg_dim=$3 disabled=$4
    local fg=$5 fg_alt=$6 accent=$7 accent_alt=$8 accent_dim=$9
    local urgent=${10} warning=${11} info=${12} success_c=${13} purple=${14} teal=${15}

    sed -i "s/^background     = .*/background     = $bg/"           "$POLYBAR_CONFIG"
    sed -i "s/^background-alt = .*/background-alt = $bg_alt/"       "$POLYBAR_CONFIG"
    sed -i "s/^background-dim = .*/background-dim = $bg_dim/"       "$POLYBAR_CONFIG"
    sed -i "s/^disabled       = .*/disabled       = $disabled/"     "$POLYBAR_CONFIG"
    sed -i "s/^foreground     = .*/foreground     = $fg/"           "$POLYBAR_CONFIG"
    sed -i "s/^foreground-alt = .*/foreground-alt = $fg_alt/"       "$POLYBAR_CONFIG"
    sed -i "s/^accent         = .*/accent         = $accent/"       "$POLYBAR_CONFIG"
    sed -i "s/^accent-alt     = .*/accent-alt     = $accent_alt/"   "$POLYBAR_CONFIG"
    sed -i "s/^accent-dim     = .*/accent-dim     = $accent_dim/"   "$POLYBAR_CONFIG"
    sed -i "s/^urgent         = .*/urgent         = $urgent/"       "$POLYBAR_CONFIG"
    sed -i "s/^warning        = .*/warning        = $warning/"      "$POLYBAR_CONFIG"
    sed -i "s/^info           = .*/info           = $info/"         "$POLYBAR_CONFIG"
    sed -i "s/^success        = .*/success        = $success_c/"    "$POLYBAR_CONFIG"
    sed -i "s/^purple         = .*/purple         = $purple/"       "$POLYBAR_CONFIG"
    sed -i "s/^teal           = .*/teal           = $teal/"         "$POLYBAR_CONFIG"

    ~/.config/polybar/launch.sh &
}

# ──────────────────────────────────────
# apply dunst
# ──────────────────────────────────────
apply_dunst() {
    local bg=$1 fg=$5 fg_alt=$6 accent_alt=$8 urgent=${10}

    sed -i "51s/background = \".*\"/background = \"$bg\"/"     "$DUNST_CONFIG"
    sed -i "57s/background = \".*\"/background = \"$bg\"/"     "$DUNST_CONFIG"
    sed -i "63s/background = \".*\"/background = \"$bg\"/"     "$DUNST_CONFIG"
    sed -i "52s/foreground = \".*\"/foreground = \"$fg\"/"     "$DUNST_CONFIG"
    sed -i "58s/foreground = \".*\"/foreground = \"$fg\"/"     "$DUNST_CONFIG"
    sed -i "64s/foreground = \".*\"/foreground = \"$fg_alt\"/" "$DUNST_CONFIG"
    sed -i "53s/frame_color = \".*\"/frame_color = \"$accent_alt\"/" "$DUNST_CONFIG"
    sed -i "59s/frame_color = \".*\"/frame_color = \"$accent_alt\"/" "$DUNST_CONFIG"
    sed -i "65s/frame_color = \".*\"/frame_color = \"$urgent\"/"     "$DUNST_CONFIG"
    sed -i "22s/foreground='[^']*'>%s/foreground='$accent_alt'>%s/"  "$DUNST_CONFIG"
    sed -i "22s/foreground='[^']*'>%b/foreground='$fg'>%b/"          "$DUNST_CONFIG"

    killall dunst 2>/dev/null
    dunst &
}

# ──────────────────────────────────────
# apply rofi
# ──────────────────────────────────────
apply_rofi() {
    local bg=$1 bg_alt=$2 bg_dim=$3 disabled=$4
    local fg=$5 fg_alt=$6 accent=$7 accent_alt=$8

    # ── nord.rasi ──
    sed -i "s/nord0: .*/nord0: $bg;/"              "$ROFI_NORD"
    sed -i "s/nord1: .*/nord1: $bg_alt;/"           "$ROFI_NORD"
    sed -i "s/nord2: .*/nord2: $bg_dim;/"           "$ROFI_NORD"
    sed -i "s/nord3: .*/nord3: $disabled;/"         "$ROFI_NORD"
    sed -i "s/nord4: .*/nord4: $fg;/"               "$ROFI_NORD"
    sed -i "s/nord6: .*/nord6: $fg_alt;/"           "$ROFI_NORD"
    sed -i "s/nord8: .*/nord8: $accent_alt;/"       "$ROFI_NORD"
    sed -i "s/nord10: .*/nord10: $accent;/"         "$ROFI_NORD"
    sed -i "s/background-color: #[0-9a-fA-F]\{6\};$/background-color: $bg_alt;/" "$ROFI_NORD"
    sed -i "s/background-color: rgba([^)]*);/background-color: $bg;/"             "$ROFI_NORD"
    sed -i "/element selected.normal/,/}/{s/text-color: #[0-9a-fA-F]\{6\};/text-color: $bg;/}" "$ROFI_NORD"

    # ── sidetab-nord.rasi ──
    sed -i "s/^    background: .*/    background: $bg;/"             "$ROFI_SIDE"
    sed -i "s/^    foreground: .*/    foreground: $fg;/"             "$ROFI_SIDE"
    sed -i "s/^    bg-selected: .*/    bg-selected: $accent_alt;/"   "$ROFI_SIDE"
    sed -i "s/^    grey: .*/    grey: $disabled;/"                   "$ROFI_SIDE"
    sed -i "/#inputbar/,/}/{s/background-color: #[0-9a-fA-F]\{6\};/background-color: $bg_alt;/}" "$ROFI_SIDE"
    sed -i "/#scrollbar {/,/}/{s/background-color: #[0-9a-fA-F]\{6\};/background-color: $bg_alt;/}" "$ROFI_SIDE"
    sed -i "s/background-color: .*\/\* handle \*\//background-color: $accent_alt; \/* handle *\//" "$ROFI_SIDE"
}

# ──────────────────────────────────────
# apply dwm config (no recompile)
# ──────────────────────────────────────
apply_dwm_config() {
    local bg=$1 bg_alt=$2 bg_dim=$3 disabled=$4
    local fg=$5 fg_alt=$6 accent=$7 urgent=${10}

    sed -i "s/static const char col_bg\[\].*=.*/static const char col_bg[]          = \"$bg\";/"        "$DWMDIR/config.h"
    sed -i "s/static const char col_bg2\[\].*=.*/static const char col_bg2[]         = \"$bg_alt\";/"   "$DWMDIR/config.h"
    sed -i "s/static const char col_bg3\[\].*=.*/static const char col_bg3[]         = \"$bg_dim\";/"   "$DWMDIR/config.h"
    sed -i "s/static const char col_bg4\[\].*=.*/static const char col_bg4[]         = \"$disabled\";/" "$DWMDIR/config.h"
    sed -i "s/static const char col_fg\[\].*=.*/static const char col_fg[]          = \"$fg\";/"        "$DWMDIR/config.h"
    sed -i "s/static const char col_fg2\[\].*=.*/static const char col_fg2[]         = \"$fg_alt\";/"   "$DWMDIR/config.h"
    sed -i "s/static const char col_accent\[\].*=.*/static const char col_accent[]      = \"$accent\";/"   "$DWMDIR/config.h"
    sed -i "s/static const char col_urgent\[\].*=.*/static const char col_urgent[]      = \"$urgent\";/"   "$DWMDIR/config.h"
}

# ──────────────────────────────────────
# save and get current theme
# ──────────────────────────────────────
save_theme()    { echo "$1" > "$CURRENT_FILE"; }
current_theme() { cat "$CURRENT_FILE" 2>/dev/null || echo "Nord"; }

# ──────────────────────────────────────
# apply all - one at a time
# ──────────────────────────────────────
apply_theme() {
    local name=$1
    local colors

    case $name in
        "Nord")             colors=$(theme_nord) ;;
        "Gruvbox")          colors=$(theme_gruvbox) ;;
        "Catppuccin Mocha") colors=$(theme_catppuccin) ;;
        "Tokyo Night")      colors=$(theme_tokyonight) ;;
        "Rose Pine")        colors=$(theme_rosepine) ;;
        "Breeze Dark")      colors=$(theme_breeze) ;;
        *) error "Unknown theme: $name" ;;
    esac

    read -ra c <<< "$colors"

    echo ""
    info "Switching to: $name"
    echo ""

    # step 1 - backup
    backup_configs

    # step 2 - rofi
    apply_rofi "${c[@]}" &
    wait_for $! "Applying rofi colors"

    # step 3 - dunst
    apply_dunst "${c[@]}" &
    wait_for $! "Applying dunst colors"

    # step 4 - polybar
    apply_polybar "${c[@]}" &
    wait_for $! "Applying polybar colors"

    # step 5 - dwm config update
    apply_dwm_config "${c[@]}" &
    wait_for $! "Updating dwm config"

    # step 6 - recompile dwm in terminal
    info "Opening terminal to recompile dwm..."
    st -e bash -c "
        echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
        echo ' dwm recompile — theme: $name'
        echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
        cd $DWMDIR
        sudo make clean install
        echo ''
        echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
        echo ' Make Completed'
        echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
        echo 'Restart DWM to take full effect of the $name theme.'
        echo ' Done! Closing in 3 seconds...'
        sleep 3
    "

    save_theme "$name"
    notify-send "Theme Switcher" "Applied: $name" 2>/dev/null
    echo ""
    success "Theme '$name' applied successfully"
}

# ──────────────────────────────────────
# rofi menu
# ──────────────────────────────────────
THEMES=(
    "Nord"
    "Gruvbox"
    "Catppuccin Mocha"
    "Tokyo Night"
    "Rose Pine"
    "Breeze Dark"
)

current=$(current_theme)

menu=""
for t in "${THEMES[@]}"; do
    if [ "$t" = "$current" ]; then
        menu+=" $t\n"
    else
        menu+="  $t\n"
    fi
done

selected=$(echo -e "$menu" | rofi \
    -dmenu \
    -i \
    -p " Theme" \
    -theme sidetab-nord \
    -theme-str 'window {width: 350px;}' \
    -theme-str 'listview {lines: 6;}')

selected=$(echo "$selected" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')

if [ -n "$selected" ]; then
    apply_theme "$selected"
fi
