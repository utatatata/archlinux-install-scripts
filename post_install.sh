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
printf "\n${GREEN}Arch Linux Install Script (Additional Settings)${RESET}\n\n\n"

#################### User name ####################

if [[ ! -v ALIS_USER_NAME || \
  "${ALIS_USER_NAME}" = "" ]]; then
  while true; do
    read -p "New user name: " ALIS_USER_NAME

    if [[ "${ALIS_USER_NAME}" = "" ]]; then
      error "invalid value: user name must not be empty"
      echo ""
    else
      break
    fi
  done

  echo ""
fi

username="${ALIS_USER_NAME}"

#################### User passwd ####################

if [[ ! -v ALIS_USER_PASSWD || \
  "${ALIS_USER_PASSWD}" = "" ]]; then
  while true; do
    read -sp "User password: " userpasswd1 && echo ""
    read -sp "Retype user password: " userpasswd2 && echo ""

    if [[ ! "${userpasswd1}" = "${userpasswd2}" ]]; then
      error "passwords do not match"
      echo ""
    elif [[ "${userpasswd1}" = "" ]]; then
      error "invalid value: password must not be empty"
      echo ""
    else
      ALIS_USER_PASSWD=${userpasswd1}
      break
    fi
  done

  echo ""
fi

userpasswd=${ALIS_USER_PASSWD}

#################### POST INSTALL ####################

# Swap file
pacman --noconfirm -S systemd-swap
systemctl enable systemd-swap

# Add a new user
useradd -m -G wheel -s /bin/bash ${username}
passwd ${username} <<EOF
${userpasswd}
${userpasswd}
EOF

# Privilege elevation
cp /etc/sudoers /etc/newsudoers
sed -e 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' \
  -i /etc/newsudoers
visudo -qcf /etc/newsudoers
if [[ "$?" = "0" ]]; then
  mv -f /etc/newsudoers /etc/sudoers
else
  rm /etc/newsudoers
  printf "\n\n\n"
  error "Failed to edit /etc/sudoers"
  exit 1
fi

# Utilizing multiple cores for makepkg
sed -e 's/^\(CFLAGS=.*\)$/#\1\nCFLAGS="-march=native -O2 -pipe -fstack-protector-strong"/' \
  -e 's/^\(CXXFLAGS=.*\)$/#\1\nCXXFLAGS=${CFLAGS}/' \
  -e "s/^\(#MAKEFLAGS=.*\)\$/\1\nMAKEFLAGS=\"-j$(nproc)\"/" \
  -i /etc/makepkg.conf
pacman --noconfirm -S pigz pbzip2
sed -e 's/COMPRESSXZ=(xz -c -z -)/COMPRESSXZ=(xz -c -z - --threads=0)/' \
  -e 's/COMPRESSGZ=(gzip -c -f -n)/COMPRESSGZ=(pigz -c -f -n)/' \
  -e 's/COMPRESSBZ2=(bzip2 -c -f)/COMPRESSBZ2=(pbzip2 -c -f)/' \
  -e 's/COMPRESSZST=(zstd -c -z -q -)/COMPRESSZST=(zstd -c -z -q - --threads=0)/' \
  -i /etc/makepkg.conf

# AUR helper (Yay)
# Dependencies
pacman --noconfirm -S git go
userhome=$(eval echo ~${username})
pushd ${userhome}
sudo -u ${username} git clone https://aur.archlinux.org/yay.git
cd yay
# Build (makepkg is not allowed to run as root)
sudo -u ${username} sudo -K
sudo -Su ${username} makepkg <<EOF
${userpasswd}
EOF
# Install
pacman --noconfirm -U ./*.pkg.tar.xz
popd
rm -rf ${userhome}/yay
pacman --noconfirm -Rns go
sudo -u ${username} yay --save --sudoloop

# Pacman wrapper (Powerpill)
sudo -u ${username} sudo -K
sudo -u ${username} yay --sudoflags -S --noconfirm -S powerpill jq <<EOF
${userpasswd}
EOF
sed -e 's/^\(SigLevel.*\)$/#\1\nSigLevel = PackageRequired/' \
  -i /etc/pacman.conf
rsyncservers=$(reflector -p rsync -c JP -c KR -c HK -c TW | sed -e '/^#/d' -e '/^$/d')
jq ".rsync.servers = [$(echo "${rsyncservers}" | sed -e 's/^\(.*\)$/\"\1\"/g' | paste -sd ',')]" \
  /etc/powerpill/powerpill.json >/etc/powerpill/powerpill.json
# Use powerpill instead of pacman inside yay
sudo -u ${username} yay --save --pacman powerpill

# Clock synchronization (systemd-timesyncd)
cat <<EOF >>/etc/systemd/timesyncd.conf
NTP=0.arch.pool.ntp.org 1.arch.pool.ntp.org 2.arch.pool.ntp.org 3.arch.pool.ntp.org
FallbackNTP=0.pool.ntp.org 1.pool.ntp.org 0.fr.pool.ntp.org
EOF
timedatectl set-ntp true

#################### FINISH ####################

printf "\n\n"
printf "+--------------------------+\n"
printf "| ${CYAN}Successfully Installed!!${RESET} |\n"
printf "+--------------------------+\n\n\n"

exit
