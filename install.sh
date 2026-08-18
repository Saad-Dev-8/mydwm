#!/bin/bash

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
    if [ -f /etc/os-release ]; then
        . /etc/os-release

        if [ "$ID" = "arch" ] || echo "${ID_LIKE:-}" | grep -qw "arch"; then
            echo "arch"
            return
        fi

        if [ "$ID" = "debian" ] || echo "${ID_LIKE:-}" | grep -qw "debian"; then
            echo "debian"
            return
        fi

        if [ "$ID" = "ubuntu" ] || echo "${ID_LIKE:-}" | grep -qw "ubuntu"; then
            echo "debian"
            return
        fi

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

# detect xorg or xlibre
detect_xserver() {
    # check if xlibre is installed (fork of xorg)
    if pacman -Qi xlibre-xserver &>/dev/null || pacman -Qi xlibre &>/dev/null; then
        echo "xlibre"
        return
    fi

    # check if xorg is installed
    if pacman -Qi xorg-server &>/dev/null || \
       dpkg -s xserver-xorg &>/dev/null 2>&1 || \
       rpm -q xorg-x11-server-Xorg &>/dev/null 2>&1; then
        echo "xorg"
        return
    fi

    # check running display server via xdpyinfo
    if [ -n "$DISPLAY" ]; then
        local server
        server=$(xdpyinfo 2>/dev/null | grep "X\.Org\|XLibre" | head -1)
        if echo "$server" | grep -qi "xlibre"; then
            echo "xlibre"
            return
        elif echo "$server" | grep -qi "x\.org"; then
            echo "xorg"
            return
        fi
    fi

    echo "none"
}

XSERVER=$(detect_xserver)
case $XSERVER in
    xlibre)  info "X server: XLibre detected" ;;
    xorg)    info "X server: Xorg detected" ;;
    none)    warning "No X server detected — will install xorg" ;;
esac

# install xorg if no x server detected
install_xorg() {
    if [ "$XSERVER" = "none" ]; then
        info "Installing Xorg..."
        case $DISTRO in
            arch)
                sudo pacman -S --needed --noconfirm \
                    xorg-server \
                    xorg-xinit \
                    xorg-xrandr \
                    xorg-xsetroot || error "Failed to install Xorg packages on Arch"
                ;;
            debian)
                sudo apt update || error "Failed to update apt cache"
                sudo apt install -y \
                    xserver-xorg \
                    xinit \
                    x11-xserver-utils || error "Failed to install Xorg packages on Debian"
                ;;
            fedora)
                sudo dnf install -y \
                    xorg-x11-server-Xorg \
                    xorg-x11-xinit \
                    xorg-x11-utils || error "Failed to install Xorg packages on Fedora"
                ;;
        esac
        success "Xorg installed"
    else
        info "Skipping Xorg install — $XSERVER already present"
    fi
}

# install dependencies
install_deps() {
    info "Installing dependencies..."

    # install xorg if needed
    install_xorg

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
                firefox || error "Failed to install dependencies on Arch"
            ;;
        debian)
            sudo apt update || error "Failed to update apt cache"
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
                firefox-esr || error "Failed to install dependencies on Debian"
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
                firefox || error "Failed to install dependencies on Fedora"
            ;;
        *)
            error "Unknown distro — unsupported system"
            ;;
    esac

    success "Dependencies installed"
}

# build and install dwm
install_dwm() {
    info "Building dwm..."
    cd "$DWMDIR" || error "Failed to change to $DWMDIR"
    sudo make clean install || error "dwm build failed"
    success "dwm installed"
}

# install config files
install_configs() {
    info "Installing config files..."

    mkdir -p ~/.config/picom || error "Failed to create ~/.config/picom"
    mkdir -p ~/.config/dunst || error "Failed to create ~/.config/dunst"
    mkdir -p ~/.config/polybar || error "Failed to create ~/.config/polybar"
    mkdir -p ~/.config/rofi || error "Failed to create ~/.config/rofi"
    mkdir -p ~/.config/betterlockscreen || error "Failed to create ~/.config/betterlockscreen"

    # picom
    if [ -d "$CONFIGDIR/picom" ]; then
        cp -r "$CONFIGDIR/picom/"* ~/.config/picom/ || error "Failed to copy picom config"
        success "picom config installed"
    else
        error "picom config not found in $CONFIGDIR/picom"
    fi

    # dunst
    if [ -d "$CONFIGDIR/dunst" ]; then
        cp -r "$CONFIGDIR/dunst/"* ~/.config/dunst/ || error "Failed to copy dunst config"
        success "dunst config installed"
    else
        error "dunst config not found in $CONFIGDIR/dunst"
    fi

    # polybar
    if [ -d "$CONFIGDIR/polybar" ]; then
        cp -r "$CONFIGDIR/polybar/"* ~/.config/polybar/ || error "Failed to copy polybar config"
        chmod +x ~/.config/polybar/launch.sh 2>/dev/null || warning "Could not make polybar launch.sh executable"
        chmod +x ~/.config/polybar/scripts/*.sh 2>/dev/null || warning "Could not make polybar scripts executable"
        success "polybar config installed"
    else
        error "polybar config not found in $CONFIGDIR/polybar"
    fi

    # rofi
    if [ -d "$CONFIGDIR/rofi" ]; then
        cp -r "$CONFIGDIR/rofi/"* ~/.config/rofi/ || error "Failed to copy rofi config"
        chmod +x ~/.config/rofi/powermenu.sh 2>/dev/null || warning "Could not make rofi powermenu.sh executable"
        success "rofi config installed"
    else
        error "rofi config not found in $CONFIGDIR/rofi"
    fi

    # betterlockscreen
    if [ -d "$CONFIGDIR/betterlockscreen" ]; then
        cp -r "$CONFIGDIR/betterlockscreen/"* ~/.config/betterlockscreen/ || error "Failed to copy betterlockscreen config"
        success "betterlockscreen config installed"
    else
        error "betterlockscreen config not found in $CONFIGDIR/betterlockscreen"
    fi
}

# install autostart script
install_autostart() {
    info "Installing autostart..."
    mkdir -p ~/.local/share/dwm || error "Failed to create ~/.local/share/dwm"
    if [ -f "$DWMDIR/scripts/autostart.sh" ]; then
        cp "$DWMDIR/scripts/autostart.sh" ~/.local/share/dwm/autostart.sh || error "Failed to copy autostart.sh"
        chmod +x ~/.local/share/dwm/autostart.sh || error "Failed to make autostart.sh executable"
        success "autostart installed"
    else
        error "autostart.sh not found in scripts/"
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
    [ $? -eq 0 ] || error "Failed to install dwm desktop entry"
    success "dwm desktop entry installed"
}

# create wallpapers directory
setup_wallpapers() {
    if [ ! -d ~/Pictures/Wallpapers ]; then
        mkdir -p ~/Pictures/Wallpapers || error "Failed to create ~/Pictures/Wallpapers"
        warning "Created ~/Pictures/Wallpapers — add your wallpapers there"
    else
        success "Wallpapers directory exists"
    fi
}

main() {
    echo ""
    echo "What would you like to install?"
    echo "  1) Everything (recommended)"
    echo "  2) dwm only"
    echo "  3) configs only"
    echo "  4) deps only"
    echo ""
    
    # Validate input
    while true; do
        read -rp "Choice [1-4]: " choice
        case $choice in
            1)
                install_deps
                install_dwm
                install_configs
                install_autostart
                install_desktop_entry
                setup_wallpapers
                break
                ;;
            2)
                install_dwm
                break
                ;;
            3)
                install_configs
                install_autostart
                break
                ;;
            4)
                install_deps
                break
                ;;
            *)
                warning "Invalid choice — please enter 1-4"
                ;;
        esac
    done

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
