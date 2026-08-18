#!/usr/bin/env bash

set -u
IFS=$'\n\t'

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SUPPORTS_EMOJI=true
if [ -z "${TERM:-}" ] || [ "$TERM" = "dumb" ] || [ -n "${CI:-}" ]; then
    SUPPORTS_EMOJI=false
fi

info() {
    if [ "$SUPPORTS_EMOJI" = true ]; then
        echo -e "${BLUE}ℹ️  $1${NC}"
    else
        echo -e "${BLUE}[INFO] $1${NC}"
    fi
}

success() {
    if [ "$SUPPORTS_EMOJI" = true ]; then
        echo -e "${GREEN}✅ $1${NC}"
    else
        echo -e "${GREEN}[OK] $1${NC}"
    fi
}

warning() {
    if [ "$SUPPORTS_EMOJI" = true ]; then
        echo -e "${YELLOW}⚠️  $1${NC}"
    else
        echo -e "${YELLOW}[WARN] $1${NC}"
    fi
}

error() {
    if [ "$SUPPORTS_EMOJI" = true ]; then
        echo -e "${RED}❌ $1${NC}" >&2
    else
        echo -e "${RED}[ERROR] $1${NC}" >&2
    fi
    exit 1
}

die() {
    error "$@"
}

cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        error "Installation failed with exit code $exit_code"
    fi
    exit $exit_code
}

trap cleanup EXIT
trap 'error "Installation interrupted by user"; exit 130' INT TERM

DWMDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)" || error "Failed to determine script directory"
readonly DWMDIR
CONFIGDIR="$DWMDIR/config"

print_header() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════╗${NC}"
    echo -e "${BLUE}║       mydwm installer        ║${NC}"
    echo -e "${BLUE}║   Enhanced & Production      ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════╝${NC}"
    echo ""
}

detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    else
        echo "unknown"
    fi
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        error "Required command not found: $1"
    fi
}

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
PRETTY_NAME=$(grep "^PRETTY_NAME" /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"' || echo "$DISTRO")
info "Detected: ${PRETTY_NAME} (family: $DISTRO)"

if [ "$DISTRO" = "unknown" ]; then
    error "Unsupported or unrecognized Linux distribution"
fi

detect_xserver() {
    if command -v pacman &>/dev/null; then
        if pacman -Qi xlibre-xserver &>/dev/null 2>&1 || pacman -Qi xlibre &>/dev/null 2>&1; then
            echo "xlibre"
            return
        fi
    fi

    case "$DISTRO" in
        arch)
            if pacman -Qi xorg-server &>/dev/null 2>&1; then
                echo "xorg"
                return
            fi
            ;;
        debian)
            if dpkg -s xserver-xorg &>/dev/null 2>&1; then
                echo "xorg"
                return
            fi
            ;;
        fedora)
            if rpm -q xorg-x11-server-Xorg &>/dev/null 2>&1; then
                echo "xorg"
                return
            fi
            ;;
    esac

    if [ -n "${DISPLAY:-}" ]; then
        local server
        server=$(xdpyinfo 2>/dev/null | grep -E "X\.Org|XLibre" | head -1) || true
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
                sudo apt-get update || error "Failed to update apt cache"
                sudo apt-get install -y \
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
            *)
                error "Unsupported distribution for Xorg installation: $DISTRO"
                ;;
        esac
        success "Xorg installed"
    else
        info "Skipping Xorg install — $XSERVER already present"
    fi
}

install_deps() {
    info "Installing dependencies..."

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
            sudo apt-get update || error "Failed to update apt cache"
            sudo apt-get install -y \
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

verify_build_environment() {
    info "Verifying build environment..."
    check_command make
    check_command gcc || check_command clang
    check_command sudo
    success "Build environment verified"
}

install_dwm() {
    info "Building dwm..."
    
    if [ ! -f "$DWMDIR/config.mk" ] && [ ! -f "$DWMDIR/Makefile" ]; then
        error "Invalid mydwm directory: $DWMDIR (config.mk or Makefile not found)"
    fi

    cd "$DWMDIR" || error "Failed to change to $DWMDIR"
    sudo make clean install || error "dwm build or installation failed"
    success "dwm installed"
}

install_configs() {
    info "Installing config files..."

    mkdir -p ~/.config/picom || error "Failed to create ~/.config/picom"
    mkdir -p ~/.config/dunst || error "Failed to create ~/.config/dunst"
    mkdir -p ~/.config/polybar || error "Failed to create ~/.config/polybar"
    mkdir -p ~/.config/rofi || error "Failed to create ~/.config/rofi"
    mkdir -p ~/.config/betterlockscreen || error "Failed to create ~/.config/betterlockscreen"

    if [ -d "$CONFIGDIR/picom" ]; then
        cp -r "$CONFIGDIR/picom/"* ~/.config/picom/ || error "Failed to copy picom config"
        success "picom config installed"
    else
        error "picom config not found in $CONFIGDIR/picom"
    fi

    if [ -d "$CONFIGDIR/dunst" ]; then
        cp -r "$CONFIGDIR/dunst/"* ~/.config/dunst/ || error "Failed to copy dunst config"
        success "dunst config installed"
    else
        error "dunst config not found in $CONFIGDIR/dunst"
    fi

    if [ -d "$CONFIGDIR/polybar" ]; then
        cp -r "$CONFIGDIR/polybar/"* ~/.config/polybar/ || error "Failed to copy polybar config"
        chmod +x ~/.config/polybar/launch.sh 2>/dev/null || warning "Could not make polybar launch.sh executable"
        find ~/.config/polybar/scripts -name "*.sh" -type f -exec chmod +x {} \; 2>/dev/null || warning "Could not make polybar scripts executable"
        success "polybar config installed"
    else
        error "polybar config not found in $CONFIGDIR/polybar"
    fi

    if [ -d "$CONFIGDIR/rofi" ]; then
        cp -r "$CONFIGDIR/rofi/"* ~/.config/rofi/ || error "Failed to copy rofi config"
        chmod +x ~/.config/rofi/powermenu.sh 2>/dev/null || warning "Could not make rofi powermenu.sh executable"
        success "rofi config installed"
    else
        error "rofi config not found in $CONFIGDIR/rofi"
    fi

    if [ -d "$CONFIGDIR/betterlockscreen" ]; then
        cp -r "$CONFIGDIR/betterlockscreen/"* ~/.config/betterlockscreen/ || error "Failed to copy betterlockscreen config"
        success "betterlockscreen config installed"
    else
        error "betterlockscreen config not found in $CONFIGDIR/betterlockscreen"
    fi
}

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

setup_wallpapers() {
    if [ ! -d ~/Pictures/Wallpapers ]; then
        mkdir -p ~/Pictures/Wallpapers || error "Failed to create ~/Pictures/Wallpapers"
        warning "Created ~/Pictures/Wallpapers — add your wallpapers there"
    else
        success "Wallpapers directory exists"
    fi
}

show_completion_summary() {
    echo ""
    echo -e "${GREEN}"
    echo "  ╔══════════════════════════════════════╗"
    echo "  ║     Installation Complete! ✨       ║"
    echo "  ╚══════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    info "Next steps:"
    echo "  1. Log out and select 'dwm' from your display manager"
    echo "  2. Add wallpapers to ~/Pictures/Wallpapers"
    echo "  3. Customize keybinds in $DWMDIR/config.h"
    echo ""
    info "Quick start:"
    echo "  • Mod+P  - rofi launcher"
    echo "  • Mod+Return - terminal"
    echo "  • Mod+Q  - close window"
    echo ""
}

main() {
    print_header

    echo "What would you like to install?"
    echo "  1) Everything (recommended)"
    echo "  2) dwm only"
    echo "  3) configs only"
    echo "  4) deps only"
    echo ""
    
    local choice
    local valid_choice=false
    
    while [ "$valid_choice" = false ]; do
        read -rp "Choice [1-4]: " choice
        case $choice in
            1)
                verify_build_environment
                install_deps
                install_dwm
                install_configs
                install_autostart
                install_desktop_entry
                setup_wallpapers
                valid_choice=true
                ;;
            2)
                verify_build_environment
                install_dwm
                valid_choice=true
                ;;
            3)
                install_configs
                install_autostart
                valid_choice=true
                ;;
            4)
                install_deps
                valid_choice=true
                ;;
            *)
                warning "Invalid choice — please enter 1-4"
                ;;
        esac
    done

    show_completion_summary
}

main "$@"
