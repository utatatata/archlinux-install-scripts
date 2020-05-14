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
  read -sp "[sudo] password for ${USER}: " ALIS_USER_PASSWD && echo ""

  echo ""
fi

userpasswd="${ALIS_USER_PASSWD}"

#################### Video driver ####################

if [[ ! -v ALIS_VIDEO_DRIVER ]]; then
  read -p "Video driver(default=none): " ALIS_VIDEO_DRIVER
  echo ""
fi

videodriver=${ALIS_VIDEO_DRIVER}

#################### INSTALL ####################

# Xorg
sudo -K
yay --sudoflags -S --noconfirm -S xorg-server ${videodriver} <<EOF
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

# Xfce
sudo -K
yay --sudoflags -S --noconfirm -S xfce4 <<EOF
${userpasswd}
EOF

# Audio
sudo -K
yay --sudoflags -S --noconfirm -S alsa-utils pulseaudio xfce4-pulseaudio-plugin <<EOF
${userpasswd}
EOF

# Fcitx
sudo -K
yay --sudoflags -S --noconfirm -S fcitx fcitx-im fcitx-mozc fcitx-configtool <<EOF
${userpasswd}
EOF
cat <<EOF >>${HOME}/.xprofile
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
EOF
sed -e '/^\[Hotkey\/ActivateKey\]$/,/^\[/ s/^\(DefaultValue=\)$/\1ALT_RALT/' \
  -e '/^\[Hotkey\/InactivateKey\]$/,/^\[/ s/^\(DefaultValue=\)$/\1ALT_LALT/' \
  -i /usr/share/fcitx/configdesc/config.desc
sed -e '/^\[Profile\/IMName\]$/,/^\[/ s/^\(DefaultValue=\)$/\1mozc/' \
  -e '/^\[Profile\/EnabledIMList\]$/,/^\[/ s/^\(DefaultValue=\)$/\1fcitx-keyboard-us:True,mozc:True/' \
  -i /usr/share/fcitx/configdesc/profile.desc

# Fonts
sudo -K
yay --sudoflags -S --noconfirm -S otf-ipafont <<EOF
${userpasswd}
EOF

# Browser(FireFox)
sudo -K
yay --sudoflags -S --noconfirm -S firefox <<EOF
${userpasswd}
EOF

#################### FINISH ####################

printf "\n\n"
printf "+--------------------------+\n"
printf "| ${CYAN}Successfully Installed!!${RESET} |\n"
printf "+--------------------------+\n\n\n"

exit
