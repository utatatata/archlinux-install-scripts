#!/usr/bin/env bash

set -eu

printf "\n\x1b[32mArch Linux Install Script (GUI Xfce)\x1b[m\n\n\n"


#################### User passwd ####################

if [[ ! -v  ALIS_USER_PASSWD ]]; then
  read -sp "User passwd: " ALIS_USER_PASSWD
  printf "\n\n"
fi

userpasswd="$ALIS_USER_PASSWD"


#################### Video driver ####################

if [[ ! -v  ALIS_VIDEO_DRIVER ]]; then
  read -p "Video driver: " ALIS_VIDEO_DRIVER
  echo ""
fi

videodriver=$ALIS_VIDEO_DRIVER


#################### INSTALL ####################

# Xorg
sudo -K
yay -S xorg-server $videodriver <<EOF
$userpasswd
y
EOF

# Display Manager (LightDM)
sudo -K
yay -S lightdm lightdm-gtk-greeter <<EOF
$userpasswd
y
EOF
sudo -K
sudo systemctl enable lightdm <<EOF
$userpasswd
EOF

# Xfce
sudo -K
yay -S xfce4 gamin <<EOF
$userpasswd

y
n
n
y
EOF

# Audio
sudo -K
yay -S alsa-utils pulse-audio <<EOF
$userpasswd
y
EOF

# Fcitx
sudo -K
yay -S fcitx fcitx-im fcitx-mozc fcitx-configtool <<EOF
$userpasswd
y
EOF

cat <<EOF >> ~/.xprofile
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
EOF

# Finish
printf "\n\n"
printf "+--------------------------+\n"
printf "| \x1b[36mSuccessfully Installed!!\x1b[m |\n"
printf "+--------------------------+\n\n\n"

exit
