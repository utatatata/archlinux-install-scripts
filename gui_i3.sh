#!/usr/bin/env bash

set -eu

# ANSI escape code (https://en.wikipedia.org/wiki/ANSI_escape_code)
prefix="\x1b["
suffix="m"
RESET="${prefix}${suffix}"
RED="${prefix}31${suffix}"
GREEN="${prefix}32${suffix}"
CYAN="${prefix}36${suffix}"

error() {
    printf "${RED}error${RESET}: ${1}\n"
}

#################### TITLE  ####################
printf "\n${GREEN}Arch Linux Install Script (GUI i3)${RESET}\n\n\n"

#################### User passwd ####################

if [[ ! -v ALIS_USER_PASSWD ]]; then
    read -sp "[sudo] password for $USER: " ALIS_USER_PASSWD && echo ""

    echo ""
fi

userpasswd="$ALIS_USER_PASSWD"

#################### Video driver ####################

if [[ ! -v ALIS_VIDEO_DRIVER ]]; then
    read -p "Video driver(default=none): " ALIS_VIDEO_DRIVER
    echo ""
fi

videodriver="$ALIS_VIDEO_DRIVER"

#################### Modifier key for i3 ####################

if [[ ! -v ALIS_I3_MODIFIER_KEY || ! \
    "$ALIS_I3_MODIFIER_KEY" =~ ^(win|alt)$ ]]; then
    echo "Modifier key for i3"
    echo "   1) win 2) alt"
    echo ""

    while true; do
        read -p "Enter a selection (default=1): " select

        if [[ "$select" = "1" || "$select" = "" ]]; then
            ALIS_I3_MODIFIER_KEY="win"
            break
        elif [[ "$select" = "2" ]]; then
            ALIS_I3_MODIFIER_KEY="alt"
            break
        else
            error "invalid value: $select is not between 1 and 2"
            echo ""
        fi
    done

    echo ""
fi

modkey="$ALIS_I3_MODIFIER_KEY"

#################### INSTALL ####################

# Xorg
sudo -K
yay --sudoflags -S --noconfirm -S xorg-server $videodriver <<EOF
$userpasswd
EOF

# Display Manager (LightDM)
sudo -K
yay --sudoflags -S --noconfirm -S lightdm lightdm-gtk-greeter <<EOF
$userpasswd
EOF
sudo -K
sudo -S systemctl enable lightdm <<EOF
$userpasswd
EOF

# i3
sudo -K
yay --sudoflags -S --noconfirm -S i3 xss-lock <<EOF
$userpasswd
EOF
# Generate a config file
i3-config-wizard -m "$modkey" 2>/dev/null

# Status bar (Polybar)
sudo -K
yay --sudoflags -S --noconfirm -S polybar <<EOF
$userpasswd
EOF
mkdir -p ~/.config/polybar
cat <<EOF >~/.config/polybar/launch.sh
#!/bin/bash

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Launch Polybar, using default config location ~/.config/polybar/config
polybar &

echo "Polybar launched..."
EOF
chmod +x ~/.config/polybar/launch.sh
# Config for i3
cat <<EOF >>~/.config/i3/config

# Polybar
exec_always --no-startup-id $HOME/.config/polybar/launch.sh
EOF

# Terminal emulator (Hyper)
sudo -K
yay --sudoflags -S --noconfirm -S hyper ttf-cica <<EOF
$userpasswd
EOF
mkdir -p ~/.config/Hyper
cat <<EOF >~/.config/Hyper/.hyper.js
module.exports = {
  config: {
    fontFamily: "Cica",
  }
}
EOF
# Config for i3
sed -ie 's/^\(.*exec i3-sensible-terminal.*\)$/#\1\nbindsym $mod+Return exec hyper/' \
    ~/.config/i3/config

# Launcher (Rofi)
sudo -K
yay --sudoflags -S --noconfirm -S rofi xorg-xrdb <<EOF
$userpasswd
EOF
# Download a theme
curl --create-dirs --output ~/.config/rofi/lb.rasi \
    https://raw.githubusercontent.com/davatorium/rofi-themes/master/Official%20Themes/lb.rasi
cat <<EOF >~/.config/rofi/config.rasi
configuration {
 modi: "window,drun,ssh,combi";
 theme: "lb";
 combi-modi: "window,drun,ssh";
}
EOF
# Config for i3
sed -ie 's/^\(.*exec dmenu.*\)$/#\1\nbindsym $mod+d exec rofi -show combi/' \
    ~/.config/i3/config

# Image viewer (Feh)
sudo -K
yay --sudoflags -S --noconfirm -S feh <<EOF
$userpasswd
EOF

# File manager (SpaceFM)
sudo -K
yay --sudoflags -S --noconfirm -S spacefm <<EOF
$userpasswd
EOF

# Audio
sudo -K
yay --sudoflags -S --noconfirm -S alsa-utils pulseaudio xfce4-pulseaudio-plugin <<EOF
$userpasswd
EOF

# Fcitx
sudo -K
yay --sudoflags -S --noconfirm -S fcitx fcitx-im fcitx-mozc fcitx-configtool <<EOF
$userpasswd
EOF
cat <<EOF >>~/.xprofile
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
EOF
# Generate config files
fcitx 2>/dev/null
while true; do
    if [[ -e ~/.config/fcitx/config && -e \
        ~/.config/fcitx/profile ]]; then
        sleep 1 # wait for a default settings to be written
        break
    fi
done
sed -i -e 's/#ActivateKey=/ActivateKey=ALT RALT/' \
    -e 's/#InactivateKey=/InactivateKey=ALT LALT/' \
    ~/.config/fcitx/config
sed -i -e 's/#IMName=/IMName=mozc/' \
    -e 's/mozc:False/mozc:True/' \
    ~/.config/fcitx/profile
# Config for i3
cat <<EOF >>~/.config/i3/config

# Fcitx
exec --no-startup-id fcitx
EOF

# Fonts
sudo -K
yay --sudoflags -S --noconfirm -S otf-ipafont <<EOF
$userpasswd
EOF

# Browser(FireFox)
sudo -K
yay --sudoflags -S --noconfirm -S firefox <<EOF
$userpasswd
EOF

# Shell (fish)
sudo -K
yay --sudoflags -S --noconfirm -S fish <<EOF
$userpasswd
EOF
cat <<EOF >>~/.bashrc

# Fish
exec fish
EOF
# Fisher
curl https://git.io/fisher --create-dirs -sLo ~/.config/fish/functions/fisher.fish
# Powerline (Bobthefish)
cat <<EOF >~/.config/fish/fishfile
oh-my-fish/theme-bobthefish 
EOF
cat <<EOF >~/.config/fish/config.fish
if not functions -q fisher
    set -q XDG_CONFIG_HOME; or set XDG_CONFIG_HOME ~/.config
    curl https://git.io/fisher --create-dirs -sLo $XDG_CONFIG_HOME/fish/functions/fisher.fish
    fish -c fisher
end
EOF

#################### FINISH ####################

printf "\n\n"
printf "+--------------------------+\n"
printf "| ${CYAN}Successfully Installed!!${RESET} |\n"
printf "+--------------------------+\n\n\n"

exit
