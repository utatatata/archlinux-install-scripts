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
    read -sp "[sudo] password for ${USER}: " ALIS_USER_PASSWD && echo ""

    echo ""
fi

userpasswd="${ALIS_USER_PASSWD}"

#################### Video driver ####################

if [[ ! -v ALIS_VIDEO_DRIVER ]]; then
    read -p "Video driver(default=none): " ALIS_VIDEO_DRIVER
    echo ""
fi

videodriver="${ALIS_VIDEO_DRIVER}"

#################### Modifier key for i3 ####################

if [[ ! -v ALIS_I3_MODIFIER_KEY || ! \
    "${ALIS_I3_MODIFIER_KEY}" =~ ^(win|alt)$ ]]; then
    echo "Modifier key for i3"
    echo "   1) win 2) alt"
    echo ""

    while true; do
        read -p "Enter a selection (default=1): " select

        if [[ "${select}" = "1" || "${select}" = "" ]]; then
            ALIS_I3_MODIFIER_KEY="win"
            break
        elif [[ "${select}" = "2" ]]; then
            ALIS_I3_MODIFIER_KEY="alt"
            break
        else
            error "invalid value: ${select} is not between 1 and 2"
            echo ""
        fi
    done

    echo ""
fi

if [[ "${ALIS_I3_MODIFIER_KEY}" = "win" ]]; then
    modkey="Mod4"
else
    modkey="Mod1"

fi

#################### INSTALL ####################

# Xorg
sudo -K
yay --sudoflags -S --noconfirm -S xorg-server ${videodriver} xorg-xrandr <<EOF
${userpasswd}
EOF

# Display Manager (LightDM)
sudo -K
yay --sudoflags -S --noconfirm -S lightdm lightdm-gtk-greeter <<EOF
${userpasswd}
EOF
sudo -K
sudo -S systemctl enable lightdm <<EOF
${userpasswd}
EOF

# i3
sudo -K
yay --sudoflags -S --noconfirm -S i3 xss-lock <<EOF
${userpasswd}
EOF
mkdir -p ${HOME}/.config/i3
cat /etc/i3/config >${HOME}/.config/i3/config
sed -e 's/Mod1/\$mod/g' \
    -e "1s:^\(.*\)$:\1\n\nset \$mod ${modkey}\n:" \
    -e 's/^\(exec i3-config-wizard\)$/#\1/' \
    -i ${HOME}/.config/i3/config

# Status bar (Polybar)
sudo -K
yay --sudoflags -S --noconfirm -S polybar siji-git ttf-unifont <<EOF
${userpasswd}
EOF
mkdir -p ${HOME}/.config/polybar
cat /usr/share/doc/polybar/config >${HOME}/.config/polybar/config
sed -e 's/^\(modules-left = .*\)$/#\1\nmodules-left = i3/' \
    -e 's/^\(modules-center = .*\)$/#\1/' \
    -e 's/^\(modules-right = .*\)$/#\1\nmodules-right = xbacklight pulseaudio wlan eth battery date powermenu/' \
    -i ${HOME}/.config/polybar/config
cat <<EOF >${HOME}/.config/polybar/launch.sh
#!/bin/bash

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u \$UID -x polybar >/dev/null; do sleep 1; done

# Launch Polybar, using default config location \~/.config/polybar/config
polybar example &

echo "Polybar launched..."
EOF
chmod +x ${HOME}/.config/polybar/launch.sh
# Config for i3
cat <<EOF >>${HOME}/.config/i3/config

# Polybar
exec_always --no-startup-id \$HOME/.config/polybar/launch.sh
EOF

# Terminal emulator (Hyper)
sudo -K
yay --sudoflags -S --noconfirm -S hyper ttf-cica <<EOF
${userpasswd}
EOF
cat <<EOF >${HOME}/.hyper.js
module.exports = {
  config: {
    fontFamily: "Cica",
  }
}
EOF
# Config for i3
sed -e 's/^\(.*exec i3-sensible-terminal.*\)$/#\1\nbindsym $mod+Return exec hyper/' \
    -i ${HOME}/.config/i3/config

# Launcher (Rofi)
sudo -K
yay --sudoflags -S --noconfirm -S rofi xorg-xrdb <<EOF
${userpasswd}
EOF
# Download a theme
curl --create-dirs --output ${HOME}/.config/rofi/lb.rasi \
    https://raw.githubusercontent.com/davatorium/rofi-themes/master/Official%20Themes/lb.rasi
cat <<EOF >${HOME}/.config/rofi/config.rasi
configuration {
 modi: "window,drun,ssh,combi";
 theme: "lb";
 combi-modi: "window,drun,ssh";
}
EOF
# Config for i3
sed -e 's/^\(.*exec dmenu.*\)$/#\1\nbindsym $mod+d exec rofi -show combi/' \
    -i ${HOME}/.config/i3/config

# Image viewer (Feh)
sudo -K
yay --sudoflags -S --noconfirm -S feh <<EOF
${userpasswd}
EOF

# File manager (SpaceFM)
sudo -K
yay --sudoflags -S --noconfirm -S spacefm <<EOF
${userpasswd}
EOF

# Audio
sudo -K
yay --sudoflags -S --noconfirm -S alsa-utils pulseaudio <<EOF
${userpasswd}
EOF

# Fcitx
sudo -K
yay --sudoflags -S --noconfirm -S fcitx fcitx-im fcitx-mozc fcitx-configtool otf-ipafont <<EOF
${userpasswd}
EOF
cat <<EOF >>${HOME}/.xprofile
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
EOF
# Generate config files
fcitx 2>/dev/null
while true; do
    if [[ -e ${HOME}/.config/fcitx/config && -e \
        ${HOME}/.config/fcitx/profile ]]; then
        sleep 1 # wait for a default settings to be written
        break
    fi
done
sed -i -e 's/#ActivateKey=/ActivateKey=ALT RALT/' \
    -e 's/#InactivateKey=/InactivateKey=ALT LALT/' \
    ${HOME}/.config/fcitx/config
sed -i -e 's/#IMName=/IMName=mozc/' \
    -e 's/mozc:False/mozc:True/' \
    ${HOME}/.config/fcitx/profile
# Config for i3
cat <<EOF >>${HOME}/.config/i3/config

# Fcitx
exec --no-startup-id fcitx
EOF

# Web Browser(FireFox)
sudo -K
yay --sudoflags -S --noconfirm -S firefox <<EOF
${userpasswd}
EOF

# Shell (fish)
sudo -K
yay --sudoflags -S --noconfirm -S fish <<EOF
${userpasswd}
EOF
cat <<EOF >>${HOME}/.bashrc

# Fish
exec fish
EOF
# Fisher
curl https://git.io/fisher --create-dirs -sLo ${HOME}/.config/fish/functions/fisher.fish
# Powerline (Bobthefish)
cat <<EOF >${HOME}/.config/fish/fishfile
oh-my-fish/theme-bobthefish 
EOF
fish -c fisher

#################### FINISH ####################

printf "\n\n"
printf "+--------------------------+\n"
printf "| ${CYAN}Successfully Installed!!${RESET} |\n"
printf "+--------------------------+\n\n\n"

exit
