#!/usr/bin/env bash

set -eu

# ANSI escape code (https://en.wikipedia.org/wiki/ANSI_escape_code)
prefix="\x1b["
suffix="m"
RESET="${prefix}${suffix}"
RED="${prefix}31${suffix}"
GREEN="${prefix}32${suffix}"
CYAN="${prefix}36${suffix}"

print_red() {
  printf "${RED}${1}${RESET}"
}
print_green() {
  printf "${GREEN}${1}${RESET}"
}
print_cyan() {
  printf "${CYAN}${1}${RESET}"
}

error() {
  # printf "${RED}error${RESET}: ${1}\n"
  print_red "error";
  printf ": ${1}\n"
}



#################### TITLE  ####################
print_cyan "\nArch Linux Install Script (GUI Xfce)\n\n\n"

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

# Sound
sudo -K
yay --sudoflags -S --noconfirm -S alsa-utils pulseaudio xfce4-pulseaudio-plugin <<EOF
${userpasswd}
EOF

# Fcitx
sudo -K
yay --sudoflags -S --noconfirm -S fcitx5-im fcitx5-mozc otf-ipafont <<EOF
${userpasswd}
EOF
cat <<EOF >>${HOME}/.xprofile
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
EOF

# Web Browser(FireFox)
sudo -K
yay --sudoflags -S --noconfirm -S firefox <<EOF
${userpasswd}
EOF

#################### FINISH ####################

printf "\n\n"
printf      "+--------------------------+\n"
print_green "| Successfully Installed!! |\n"
printf      "+--------------------------+\n\n\n"

exit
