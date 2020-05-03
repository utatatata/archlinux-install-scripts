#!/usr/bin/env bash

set -eu


#################### User name ####################

if [[ ! -v  ALIS_USER_NAME ]]; then
  printf "New user name: "
  read ALIS_USER_NAME
  echo ""
fi

username=$ALIS_USER_NAME


#################### User passwd ####################

if [[ ! -v ALIS_USER_PASSWD ]]; then
  while true; do
    echo ""
    printf "User password: "
    read -s userpasswd1
    echo ""
    printf "Retype root password: "
    read -s userpasswd2
    echo ""
    if [[ "$userpasswd1" = "$userpasswd2" ]]; then
      ALIS_USER_PASSWD=userpasswd1
      break
    else
      echo 'Sorry, passwords do not match.'
    fi
  done
fi

userpasswd=$ALIS_USER_PASSWD


#################### POST INSTALL ####################

# Add a new user
useradd -m -G wheel -s /bin/bash $username
passwd $username <<EOF
$userpasswd
$userpasswd
EOF

# Privilege elevation
cp /etc/sudoers /etc/newsudoers
sed -i 's/#%wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/newsudoers
visudo -qcf /etc/newsudoers
if [[ "$?" = "0" ]]; then
  mv -f /etc/newsudoers /etc/sudoers
else
  echo "Failed to edit /etc/sudoers"
  exit 1
fi

# Utilizing multiple cores on compression
pacman -S pigz pbzip2
sed -i -e 's/COMPRESSXZ=(xz -c -z -)/COMPRESSXZ=(xz -c -z - --threads=0)/' \
       -e  's/COMPRESSGZ=(gzip -c -f -n)/COMPRESSGZ=(pigz -c -f -n)/' \
       -e 's/COMPRESSBZ2=(bzip2 -c -f)/COMPRESSBZ2=(pbzip2 -c -f)/' \
       -e 's/COMPRESSZST=(zstd -c -z -q -)/COMPRESSZST=(zstd -c -z -q - --threads=0)/' /etc/makepkg.conf

# AUR helper (yay)
pacman -S git
git clone https://aur.archlinux.org/yay.git && cd yay
sudo -ku $username makepkg -si <<EOF
$userpasswd
y
EOF
cd .. && rm -rf yay
