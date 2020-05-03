#!/usr/bin/env bash

set -eu


#################### User passwd ####################

if [[ ! -v  ALIS_USER_PASSWD ]]; then
  printf "User passwd: "
  read -s ALIS_USER_PASSWD
  echo ""
fi

userpasswd="$ALIS_USER_PASSWD"


#################### User passwd ####################

if [[ ! -v  ALIS_VIDEO_DRIVER ]]; then
  printf "User passwd: "
  read ALIS_VIDEO_DRIVER
  echo ""
fi

videodriver=$ALIS_VIDEO_DRIVER


# Xorg
yay -S xorg-server $videodriver <<EOF
$userpasswd
y
EOF
sudo -K

# Display Manager (LightDM)
yay -S lightdm lightdm-gtk-greeter <<EOF
$userpasswd
y
EOF
sudo -K

# Xfce
yay -S xfce4 gamin <<EOF
$userpasswd

y
n
n
y
EOF
sudo -K

# AUdio
yay -S alsa-utils pulse-audio <<EOF
$userpasswd
y
EOF

# Fcitx
yay -S fcitx fcitx-im fcitx-mozc fcitx-configtool <<EOF
$userpasswd
y
EOF
sudo -K

cat <<EOF >> ~/.xprofile
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
EOF

