#!/usr/bin/env bash

set -eu

# ANSI escape code (https://en.wikipedia.org/wiki/ANSI_escape_code)
prefix="\x1b["
suffix="m"
RESET="${prefix}${suffix}"
GREEN="${prefix}32${suffix}"
CYAN="${prefix}36${suffix}"

#################### TITLE  ####################
printf "\n${GREEN}Arch Linux Install Script (GUI Xfce)${RESET}\n\n\n"

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

videodriver=$ALIS_VIDEO_DRIVER

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

# Xfce
sudo -K
yay --sudoflags -S --noconfirm -S xfce4 <<EOF
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

#################### FINISH ####################

printf "\n\n"
printf "+--------------------------+\n"
printf "| ${CYAN}Successfully Installed!!${RESET} |\n"
printf "+--------------------------+\n\n\n"

exit
