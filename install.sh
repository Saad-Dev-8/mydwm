#!/bin/bash
# mydwm install script
# installs dwm, configs and dependencies

set -e

# colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# get script directory (mydwm root)
DWMDIR="$(cd "$(dirname "$0")" && pwd)"
CONFIGDIR="$DWMDIR/config"

echo -e "${BLUE}"
echo "  ╔══════════════════════════════╗"
echo "  ║       mydwm installer        ║"
echo "  ╚══════════════════════════════╝"
echo -e "${NC}"

# detect distro family
detect_distro() {
    # check /etc/os-release for ID and ID_LIKE fields
    if [ -f /etc/os-release ]; then
        . /etc/os-release

        # check if it's arch or arch-based (manjaro, endeavouros, garuda, etc)
        if [ "$ID" = "arch" ] || echo "${ID_LIKE:-}" | grep -qw "arch"; then
            echo "arch"
            return
        fi

        # check if it's debian or debian-based (ubuntu, mint, pop, etc)
        if [ "$ID" = "debian" ] || echo "${ID_LIKE:-}" | grep -qw "debian"; then
            echo "debian"
            return
        fi

        # check if it's ubuntu-based (ubuntu itself has ID=ubuntu not ID_LIKE=debian)
        if [ "$ID" = "ubuntu" ] || echo "${ID_LIKE:-}" | grep -qw "ubuntu"; then
            echo "debian"
            return
        fi

        # fedora or fedora-based (nobara, ultramarine, etc)
        if [ "$ID" = "fedora" ] || echo "${ID_LIKE:-}" | grep -qw "fedora"; then
            echo "fedora"
            return
        fi
    fi

    # fallback checks
    if [ -f /etc/arch-release ]; then
        echo "arch"
    elif [ -f /etc/debian_version ]; then
        echo "debian"
    elif [ -f /etc/fedora-release ]; then
        echo "fedora"
    else
        echo "unknown"
    fi
}

DISTRO=$(detect_distro)
PRETTY_NAME=$(grep "^PRETTY_NAME" /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"')
info "Detected: ${PRETTY_NAME:-$DISTRO} (family: $DISTRO)"

# install dependencies
install_deps() {
    info "Installing dependencies..."

    case $DISTRO in
        arch)
            sudo pacman -S --needed --noconfirm \
                base-devel \
                libx11 \
                libxft \
                libxinerama \
                yajl \
                jq \
                xorg-xprop \
                xdotool \
                picom \
                dunst \
                feh \
                flameshot \
                unclutter \
                polybar \
                rofi \
                brightnessctl \
                xclip \
                xorg-xsetroot \
                ttf-jetbrains-mono-nerd \
                betterlockscreen \
                pcmanfm \
                firefox
            ;;
        debian)
            sudo apt update
            sudo apt install -y \
                build-essential \
                libx11-dev \
                libxft-dev \
                libxinerama-dev \
                libyajl-dev \
                jq \
                x11-utils \
                xdotool \
                picom \
                dunst \
                feh \
                flameshot \
                unclutter \
                polybar \
                rofi \
                brightnessctl \
                xclip \
                x11-xserver-utils \
                fonts-jetbrains-mono \
                pcmanfm \
                firefox-esr
            ;;
        fedora)
            sudo dnf install -y \
                @development-tools \
                libX11-devel \
                libXft-devel \
                libXinerama-devel \
                yajl-devel \
                jq \
                xprop \
                xdotool \
                picom \
                dunst \
                feh \
                flameshot \
                unclutter \
                polybar \
                rofi \
                brightnessctl \
                xclip \
                xsetroot \
                pcmanfm \
                firefox
            ;;
        *)
            warning "Unknown distro — skipping dependency install"
            warning "Please install dependencies manually"
            ;;
    esac

    success "Dependencies installed"
}

# build and install dwm
install_dwm() {
    info "Building dwm..."
    cd "$DWMDIR"
    sudo make clean install || error "dwm build failed"
    success "dwm installed"
}

# install config files
install_configs() {
    info "Installing config files..."

    # create config dirs if they don't exist
    mkdir -p ~/.config/picom
    mkdir -p ~/.config/dunst
    mkdir -p ~/.config/polybar
    mkdir -p ~/.config/rofi
    mkdir -p ~/.config/betterlockscreen

    # picom
    if [ -d "$CONFIGDIR/picom" ]; then
        cp -r "$CONFIGDIR/picom/"* ~/.config/picom/
        success "picom config installed"
    else
        warning "picom config not found in $CONFIGDIR/picom"
    fi

    # dunst
    if [ -d "$CONFIGDIR/dunst" ]; then
        cp -r "$CONFIGDIR/dunst/"* ~/.config/dunst/
        success "dunst config installed"
    else
        warning "dunst config not found in $CONFIGDIR/dunst"
    fi

    # polybar
    if [ -d "$CONFIGDIR/polybar" ]; then
        cp -r "$CONFIGDIR/polybar/"* ~/.config/polybar/
        # make sure launch script is executable
        chmod +x ~/.config/polybar/launch.sh 2>/dev/null || true
        chmod +x ~/.config/polybar/scripts/*.sh 2>/dev/null || true
        success "polybar config installed"
    else
        warning "polybar config not found in $CONFIGDIR/polybar"
    fi

    # rofi
    if [ -d "$CONFIGDIR/rofi" ]; then
        cp -r "$CONFIGDIR/rofi/"* ~/.config/rofi/
        chmod +x ~/.config/rofi/powermenu.sh 2>/dev/null || true
        success "rofi config installed"
    else
        warning "rofi config not found in $CONFIGDIR/rofi"
    fi

    # betterlockscreen
    if [ -d "$CONFIGDIR/betterlockscreen" ]; then
        cp -r "$CONFIGDIR/betterlockscreen/"* ~/.config/betterlockscreen/
        success "betterlockscreen config installed"
    else
        warning "betterlockscreen config not found in $CONFIGDIR/betterlockscreen"
    fi
}

# install autostart script
install_autostart() {
    info "Installing autostart..."
    mkdir -p ~/.local/share/dwm
    if [ -f "$DWMDIR/scripts/autostart.sh" ]; then
        cp "$DWMDIR/scripts/autostart.sh" ~/.local/share/dwm/autostart.sh
        chmod +x ~/.local/share/dwm/autostart.sh
        success "autostart installed"
    else
        warning "autostart.sh not found in scripts/"
    fi
}

# install dwm desktop entry for lightdm
install_desktop_entry() {
    info "Installing dwm desktop entry..."
    sudo tee /usr/share/xsessions/dwm.desktop > /dev/null << 'EOF'
[Desktop Entry]
Encoding=UTF-8
Name=dwm
Comment=Dynamic Window Manager
Exec=dwm
Icon=dwm
Type=XSession
EOF
    success "dwm desktop entry installed"
}

# create wallpapers directory
setup_wallpapers() {
    if [ ! -d ~/Pictures/Wallpapers ]; then
        mkdir -p ~/Pictures/Wallpapers
        warning "Created ~/Pictures/Wallpapers — add your wallpapers there"
    else
        success "Wallpapers directory exists"
    fi
}

# main
main() {
    # ask what to install
    echo ""
    echo "What would you like to install?"
    echo "  1) Everything (recommended)"
    echo "  2) dwm only"
    echo "  3) configs only"
    echo "  4) deps only"
    echo ""
    read -rp "Choice [1-4]: " choice

    case $choice in
        1)
            install_deps
            install_dwm
            install_configs
            install_autostart
            install_desktop_entry
            setup_wallpapers
            ;;
        2)
            install_dwm
            ;;
        3)
            install_configs
            install_autostart
            ;;
        4)
            install_deps
            ;;
        *)
            error "Invalid choice"
            ;;
    esac

    echo ""
    echo -e "${GREEN}"
    echo "  ╔══════════════════════════════╗"
    echo "  ║     installation complete    ║"
    echo "  ╚══════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    info "Log out and select dwm from your display manager"
    info "Add wallpapers to ~/Pictures/Wallpapers"
    echo ""
}

main
