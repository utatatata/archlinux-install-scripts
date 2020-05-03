#!/usr/bin/env bash

set -eu

printf "\n\x1b[32mArch Linux Install Script (Additional Settings)\x1b[m\n\n"

#################### User name ####################

if [[ ! -v  ALIS_USER_NAME ]]; then
  read -p "New user name: " ALIS_USER_NAME
  echo ""
fi

username="$ALIS_USER_NAME"


#################### User passwd ####################

if [[ ! -v ALIS_USER_PASSWD ]]; then
  while true; do
    read -sp "User password: " userpasswd1
    echo ""
    read -sp "Retype root password: " userpasswd2
    echo ""
    if [[ "$userpasswd1" = "$userpasswd2" ]]; then
      ALIS_USER_PASSWD="$userpasswd1"
      break
    else
      printf "\x1b[31merror\x1b[m: passwords do not match\n\"
    fi
  done
fi

userpasswd=$ALIS_USER_PASSWD


#################### POST INSTALL ####################

# Swap file
pacman -S systemd-swap <<EOF
y
EOF
systemctl enable systemd-swap

# Add a new user
useradd -m -G wheel -s /bin/bash $username
passwd $username <<EOF
$userpasswd
$userpasswd
EOF

# Privilege elevation
cp /etc/sudoers /etc/newsudoers
sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/newsudoers
visudo -qcf /etc/newsudoers
if [[ "$?" = "0" ]]; then
  mv -f /etc/newsudoers /etc/sudoers
else
  echo "Failed to edit /etc/sudoers"
  exit 1
fi

# Utilizing multiple cores on compression
pacman -S pigz pbzip2 <<EOF
y
EOF
sed -i -e 's/COMPRESSXZ=(xz -c -z -)/COMPRESSXZ=(xz -c -z - --threads=0)/' \
       -e  's/COMPRESSGZ=(gzip -c -f -n)/COMPRESSGZ=(pigz -c -f -n)/' \
       -e 's/COMPRESSBZ2=(bzip2 -c -f)/COMPRESSBZ2=(pbzip2 -c -f)/' \
       -e 's/COMPRESSZST=(zstd -c -z -q -)/COMPRESSZST=(zstd -c -z -q - --threads=0)/' /etc/makepkg.conf

# AUR helper (yay)
pacman -S git go <<EOF
y
EOF
userhome=$(eval echo ~$username)
pushd $userhome
sudo -u $username git clone https://aur.archlinux.org/yay.git
cd yay
sudo -u $username makepkg -sr
popd
rm -rf $userhome/yay
pacman -Rns go <<EOF
y
EOF

# Finish
echo ""
printf "+--------------------------+\n"
printf "| \x1b[36mSuccessfully Installed!!\x1b[m |\n"
printf "+--------------------------+\n\n"

exit
