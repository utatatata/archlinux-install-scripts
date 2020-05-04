#!/usr/bin/env bash

set -eu

printf "\n\x1b[32mArch Linux Install Script (GUI Xfce)\x1b[m\n\n\n"


#################### User passwd ####################

if [[ ! -v  ALIS_USER_PASSWD ]]; then
  read -sp "[sudo] password for $USER: " ALIS_USER_PASSWD
  printf "\n\n"
fi

userpasswd="$ALIS_USER_PASSWD"


#################### Video driver ####################

if [[ ! -v  ALIS_VIDEO_DRIVER ]]; then
  read -p "Video driver(default=none): " ALIS_VIDEO_DRIVER
  echo ""
fi

videodriver=$ALIS_VIDEO_DRIVER


#################### INSTALL ####################

# Xorg
sudo -K
yay --sudoflags -S --sudoloop -S xorg-server $videodriver <<EOF
$userpasswd
y
EOF

# Display Manager (LightDM)
sudo -K
yay --sudoflags -S --sudoloop -S lightdm lightdm-gtk-greeter <<EOF
$userpasswd
y
EOF
sudo -K
sudo -S systemctl enable lightdm <<EOF
$userpasswd
EOF

# Xfce
sudo -K
yay --sudoflags -S --sudoloop -S xfce4 <<EOF
$userpasswd

y
EOF

# Audio
sudo -K
yay --sudoflags -S --sudoloop -S alsa-utils pulseaudio <<EOF
$userpasswd
y
EOF

# Fcitx
sudo -K
yay --sudoflags -S --sudoloop -S fcitx fcitx-im fcitx-mozc fcitx-configtool <<EOF
$userpasswd

y
EOF

# Fonts
sudo -K
yay --sudoflags -S --sudoloop -S otf-ipafont <<EOF
$userpasswd
y
EOF

cat <<EOF >> ~/.xprofile
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
EOF

# Browser(FireFox)
sudo -K
yay --sudoflags -S --sudoloop -S firefox <<EOF
$userpasswd
2
y
EOF

# Finish
printf "\n\n"
printf "+--------------------------+\n"
printf "| \x1b[36mSuccessfully Installed!!\x1b[m |\n"
printf "+--------------------------+\n\n\n"

exit
