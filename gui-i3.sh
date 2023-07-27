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
print_cyan "\nArch Linux Install Script (GUI i3)\n\n\n"

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

#################### Font size ####################

if [[ -v ALIS_FONT_SIZE && \
  "${ALIS_FONT_SIZE}" != "" ]]; then
  if expr "$ALIS_FONT_SIZE" : "[0-9]*$" >&/dev/null; then
    unset ALIS_FONT_SIZE
  fi
fi

if [[ ! -v ALIS_FONT_SIZE || \
  "${ALIS_FONT_SIZE}" = "" ]]; then
  while true; do
    read -ep "font size: " ALIS_FONT_SIZE

    if expr "$ALIS_FONT_SIZE" : "[0-9]*$" >&/dev/null; then
      break
    else
      error "invalid value: font size must be a natural number"
      echo ""
    fi
  done

  echo ""
fi

fontsize="${ALIS_FONT_SIZE}"

#################### INSTALL ####################

# Xorg
sudo -K
yay --sudoflags -S --noconfirm -S xorg-server ${videodriver} <<EOF
${userpasswd}
EOF

# Official configuration utility to the RandR (xrandr)
sudo -K
yay --sudoflags -S --noconfirm -S xorg-xrandr arandr <<EOF
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

# Fonts
sudo -K
yay --sudoflags -S --noconfirm -S ttf-cica <<EOF
${userpasswd}
EOF

# i3
sudo -K
yay --sudoflags -S --noconfirm -S i3 <<EOF
${userpasswd}
EOF
mkdir -p ${HOME}/.config/i3
# i3-config-wizard requires X server, so the configuration file is generated by manually
cat /etc/i3/config >${HOME}/.config/i3/config
sed -e 's/Mod1/\$mod/g' \
    -e "1s:^\(.*\)$:\1\n\nset \$mod ${modkey}\n:" \
    -e 's/^\(exec i3-config-wizard\)$/#\1/' \
    -i ${HOME}/.config/i3/config
# vim like cursor move
set -e 's/mod\+h/mod\+o/' \
    -e 's/mod\+j/mod\+h/' \
    -e 's/mod\+k/mod\+j/' \
    -e 's/mod\+l/mod\+k/' \
    -e 's/mod\+semicolon/mod\+l/' \
    -e 's/mod\+Shift\+j/mod\+h/' \
    -e 's/mod\+Shift\+k/mod\+j/' \
    -e 's/mod\+Shift\+l/mod\+k/' \
    -e 's/mod\+Shift\+semicolon/mod\+l/' \
    -i ${HOME}/.config/i3/config
# font settings
sed -e 's/\(^font pango.*$\)/\1\nfont pango:Cica ${fontsize}/' \
    -i ${HOME}/.config/i3/config

# Terminal emulator (Kitty)
sudo -K
yay --sudoflags -S --noconfirm -S kitty <<EOF
${userpasswd}
EOF
# Config for i3
sed -e 's/^\(.*exec i3-sensible-terminal.*\)$/#\1\nbindsym $mod+Return exec kitty/' \
    -i ${HOME}/.config/i3/config

# Application launchers (Rofi)
sudo -K
yay --sudoflags -S --noconfirm -S rofi <<EOF
${userpasswd}
EOF
# Download a theme
curl --create-dirs --output ${HOME}/.config/rofi/lb.rasi \
    https://raw.githubusercontent.com/davatorium/rofi-themes/master/Official%20Themes/lb.rasi
cat <<EOF >${HOME}/.config/rofi/config.rasi
configuration {
 modi: "drun,ssh";
 hide-scrollbar: true;
 kb-element-next: "";
 kb-mode-next: "Tab";
}
@theme "lb"
EOF
# Config for i3
sed -e 's/^\(.*exec dmenu.*\)$/#\1\nbindsym $mod+d exec rofi -show/' \
    -i ${HOME}/.config/i3/config

# Sound
sudo -K
yay --sudoflags -S --noconfirm -S alsa-utils <<EOF
${userpasswd}
EOF

# Fcitx
sudo -K
yay --sudoflags -S --noconfirm -S fcitx5-im fcitx5-mozc <<EOF
${userpasswd}
EOF
cat <<EOF >>${HOME}/.xprofile
export  GTK_IM_MODULE=fcitx
export   QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export GLFW_IM_MODULE=ibus
EOF
mkdir -p ${HOME}/.config/fcitx5
cat <<EOF >${HOME}/.config/fcitx5/profile
[Groups/0]
Name = Default
Default Layout=us
DefaultIM=mozc

[Groups0/Items/0]
Name=keyboard-us
Layout=

[Groups0/Items/1]
Name=mozc
Layout=

[GroupOrder]
0=Default
EOF
cat <<EOF >${HOME}/.config/fcitx5/config
[Hotkey/ActivateKeys]
0=Alt+Alt_R

[Hotkey/DeactivateKeys]
0=Alt+Alt_L

EOF
# fcitx5 &>/dev/null
# sed -e 's/\(^\[GroupOrder\]$\)/\[Group\/0\/Items\/1\]\n# Name\nName=mozc\n# Layout\nLayout=\n\n\1/'
#     -i ${HOME}/.config/fcitx5/profile
# sed -e 's/ActivateKey\]\n\(0=.*$\)/ActivateKey\]\n#\1\n0=Alt+ALt_R/'
#     -e 's/DeactivateKey\]\n\(0=.*$\)/DeactivateKey\]\n#\1\n0=Alt+ALt_L/'
#     -i ${HOME}/.config/fcitx5/config
# Config for i3
cat <<EOF >>${HOME}/.config/i3/config

#
# Fcitx
#
exec --no-startup-id fcitx5
EOF

# Web Browsers (chromium)
sudo -K
yay --sudoflags -S --noconfirm -S chromium <<EOF
${userpasswd}
EOF

# Shell (fish)
sudo -K
yay --sudoflags -S --noconfirm -S fish <<EOF
${userpasswd}
EOF
chsh -s /bin/fish <<EOF
${userpasswd}
EOF
# Fisher
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher

# Graphical image viewers (Feh)
sudo -K
yay --sudoflags -S --noconfirm -S feh <<EOF
${userpasswd}
EOF

# File managers (SpaceFM)
sudo -K
yay --sudoflags -S --noconfirm -S spacefm <<EOF
${userpasswd}
EOF

# Screenshot
sudo -K
yay --sudoflags -S --noconfirm -S xfce4-screenshooter <<EOF
${userpasswd}
EOF

# Editor
sudo -K
yay --sudoflags -S --noconfirm -S code <<EOF
${userpasswd}
EOF
# font settings
cat <<EOF >"${HOME}/.config/Code - OSS/User/settings.json"
{
    "editor.fontFamily": "Cica",
    "editor.fontSize": ${fontsize}
}
EOF

#################### FINISH ####################

printf "\n\n"
printf      "+--------------------------+\n"
print_green "| Successfully Installed!! |\n"
printf      "+--------------------------+\n\n\n"

exit
