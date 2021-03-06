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
printf "\n${CYAN}Arch Linux Install Script (Base System)${RESET}\n\n\n"

#################### Install device path ####################

devices=$(lsblk -dlnpo NAME)
if [[ ! -v ALIS_INSTALL_DEVICE_PATH || \
  "$(grep ^${ALIS_INSTALL_DEVICE_PATH}$ <<<${devices})" = "" ]]; then
  while true; do
    read -ep "Install device path: " ALIS_INSTALL_DEVICE_PATH

    if [[ "$(grep ^${ALIS_INSTALL_DEVICE_PATH}$ <<<${devices})" = "" ]]; then
      error "invalid path: device '${ALIS_INSTALL_DEVICE_PATH}' doesn't exists"
      echo ""
    else
      break
    fi
  done

  echo ""
fi

devicepath="${ALIS_INSTALL_DEVICE_PATH%/}"

#################### Host name ####################

if [[ ! -v ALIS_HOSTNAME || \
  "${ALIS_HOSTNAME}" = "" ]]; then
  while true; do
    read -p "Host name: " ALIS_HOSTNAME

    if [[ "${ALIS_HOSTNAME}" = "" ]]; then
      error "invalid value: hostname must not be empty"
      echo ""
    else
      break
    fi
  done

  echo ""
fi

hostname="${ALIS_HOSTNAME}"

#################### CPU manufacturer ####################

if [[ ! -v ALIS_CPU_MANUFACTURER || ! \
  "${ALIS_CPU_MANUFACTURER}" =~ ^(intel|amd)$ ]]; then
  echo "CPU platform"
  echo "   1) Intel 2) AMD"
  echo ""

  while true; do
    read -p "Enter a selection (default=1): " select

    if [[ "${select}" = "1" || "${select}" = "" ]]; then
      ALIS_CPU_MANUFACTURER="intel"
      break
    elif [[ "${select}" = "2" ]]; then
      ALIS_CPU_MANUFACTURER="amd"
      break
    else
      error "invalid value: ${select} is not between 1 and 2"
      echo ""
    fi
  done

  echo ""
fi

cpu="${ALIS_CPU_MANUFACTURER}"

#################### Root passwd ####################

if [[ ! -v ALIS_ROOT_PASSWD || \
  "${ALIS_ROOT_PASSWD}" = "" ]]; then
  while true; do
    read -sp "Root password: " rootpasswd1 && echo ""
    read -sp "Retype root password: " rootpasswd2 && echo ""

    if [[ ! "${rootpasswd1}" = "${rootpasswd2}" ]]; then
      error "passwords do not match"
      echo ""
    elif [[ "${rootpasswd1}" = "" ]]; then
      error "invalid value: password must not be empty"
      echo ""
    else
      ALIS_ROOT_PASSWD=${rootpasswd1}
      break
    fi
  done

  echo ""
fi

rootpasswd=${ALIS_ROOT_PASSWD}

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

#################### INSTALL ####################

# Update the system clock
timedatectl set-ntp true

# Partition the disks
sgdisk -og ${devicepath}
sgdisk -n 1::+260M -c 1:"EFI system partition" \
  -t 1:C12A7328-F81F-11D2-BA4B-00A0C93EC93B \
  ${devicepath}
sgdisk -n 2::+32G -c 2:"Linux x86-64 root (/)" \
  -t 2:4F68BCE3-E8CD-4DB1-96E7-FBCAF984B709 \
  ${devicepath}
sgdisk -n 3:: -c 3:"Linux /home" \
  -t 3:933AC7E1-2EB4-4F13-B844-0E14E2AEF915 \
  ${devicepath}

partitions=$(lsblk -lnpo NAME ${devicepath} | tail -n+2)
esp=$(echo "${partitions}" | head -n 1)
root=$(echo "${partitions}" | tail -n 1 | head -n 1)
home=$(echo "${partitions}" | tail -n 2 | head -n 1)

# Format the partitions
mkfs.vfat -F32 ${esp} -n "esp"
mkfs.ext4 -F ${root} -L "root"
mkfs.ext4 -F ${home} -L "home"

# Mount the file systems
mount ${root} /mnt
mkdir -p /mnt/boot
mount ${esp} /mnt/boot
mkdir -p /mnt/home
mount ${home} /mnt/home

# Select the mirrors
pacman -Sy
pacman --noconfirm -S reflector
reflector \
  -p rsync -p https -p http \
  -c JP -c KR -c HK -c TW \
  --save /etc/pacman.d/mirrorlist

# Install essential packages
pacstrap /mnt \
  base base-devel linux linux-firmware \
  dosfstools \
  networkmanager \
  vi vim \
  man-db man-pages texinfo \
  git

# Fstab
genfstab -U /mnt >>/mnt/etc/fstab

# After that, work in chroot
# Caution: `arch-chroot </path/to/new/root>` invokes bash by default,
#           but exit cannot be used to get out of bash in a shell script
#           So, in the following, each command is executed using arch-chroot

# Swap file  (systemd-swap)
arch-chroot /mnt pacman --noconfirm -S systemd-swap
arch-chroot /mnt systemctl enable systemd-swap

# Time zone
arch-chroot /mnt ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
arch-chroot /mnt hwclock --systohc

# Localization
localegen=$(cat /mnt/etc/locale.gen)
cat <<EOF >/mnt/etc/locale.gen
en_US.UTF-8 UTF-8
ja_JP.UTF-8 UTF-8
EOF
echo "${localegen}" >>/mnt/etc/locale.gen
arch-chroot /mnt locale-gen
echo "LANG=en_US.UTF-8" >/mnt/etc/locale.conf

# Network configuration (NetworkManager)
echo ${hostname} >/mnt/etc/hostname
cat <<EOF >>/mnt/etc/hosts
127.0.0.1	localhost
::1		localhost
127.0.1.1	${hostname}.localdomain	${hostname}
EOF
arch-chroot /mnt systemctl enable NetworkManager

# Root password
arch-chroot /mnt passwd <<EOF
${rootpasswd}
${rootpasswd}
EOF

# Boot loader (systemd-boot)
arch-chroot /mnt bootctl --path=/boot install
# Automatic update
mkdir -p /mnt/etc/pacman.d/hooks
cat <<EOF >/mnt/etc/pacman.d/hooks/100-systemd-boot.hook
[Trigger]
Type = Package
Operation = Upgrade
Target = systemd

[Action]
Description = Updating systemd-boot
When = PostTransaction
Exec = /usr/bin/bootctl update
EOF
# Loader configuration
cat <<EOF >/mnt/boot/loader/loader.conf
default  arch.conf
timeout  4
console-mode max
editor   no
EOF
# Adding loaders
arch-chroot /mnt pacman --noconfirm -S ${cpu}-ucode
cat <<EOF >/mnt/boot/loader/entries/arch.conf
title   Arch Linux
linux   /vmlinuz-linux
initrd  /${cpu}-ucode.img
initrd  /initramfs-linux.img
options root=UUID=$(blkid -s UUID -o value ${root}) rw
EOF

# User management
# Adding a user
arch-chroot /mnt useradd -m -G wheel -s /bin/bash ${username}
arch-chroot /mnt passwd ${username} <<EOF
${userpasswd}
${userpasswd}
EOF

# Privilege elevation (sudo)
cp /mnt/etc/sudoers ./sudoers
sed -e 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' \
  -i ./sudoers
visudo -qcf ./sudoers
if [[ "$?" = "0" ]]; then
  mv -f ./sudoers /mnt/etc/sudoers
else
  printf "\n\n\n"
  error "Failed to edit /etc/sudoers"
  exit 1
fi

# Mirrors (Reflector)
arch-chroot /mnt pacman --noconfirm -S reflector rsync
# Pacman hook
mkdir -p /mnt/etc/pacman.d/hooks
cat <<EOF >/mnt/etc/pacman.d/hooks/mirrorupgrade.hook
[Trigger]
Operation = Upgrade
Type = Package
Target = pacman-mirrorlist

[Action]
Description = Updating pacman-mirrorlist with reflector and removing pacnew...
When = PostTransaction
Depends = reflector
Exec = /bin/sh -c "reflector -c JP -c KR -c HK -c TW --latest 200 --age 24 --sort rate --save /etc/pacman.d/mirrorlist; rm -f /etc/pacman.d/mirrorlist.pacnew"
EOF
# Systemd service
cat <<EOF >/mnt/etc/systemd/system/reflector.service
[Unit]
Description=Pacman mirrorlist update
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/reflector -p rsync -p https -p http -c JP -c KR -c HK -c TW --save /etc/pacman.d/mirrorlist

[Install]
RequiredBy=multi-user.target
EOF
arch-chroot /mnt systemctl enable reflector

# Improving compile times for makepkg
sed -e "s/^\(#MAKEFLAGS=.*\)\$/\1\nMAKEFLAGS=\"-j$(nproc)\"/" \
  -i /mnt/etc/makepkg.conf
# Utilizing multiple cores for makepkg
arch-chroot /mnt pacman --noconfirm -S pigz pbzip2
sed -e 's/COMPRESSXZ=(xz -c -z -)/COMPRESSXZ=(xz -c -z - --threads=0)/' \
  -e 's/COMPRESSGZ=(gzip -c -f -n)/COMPRESSGZ=(pigz -c -f -n)/' \
  -e 's/COMPRESSBZ2=(bzip2 -c -f)/COMPRESSBZ2=(pbzip2 -c -f)/' \
  -e 's/COMPRESSZST=(zstd -c -z -q -)/COMPRESSZST=(zstd -c -z -q - --threads=0)/' \
  -i /mnt/etc/makepkg.conf

# AUR helper (Yay)
# I don't know how to pass the password to sudo, which is called inside makepkg, so I'm breaking down each installation step
# Install dependencies
arch-chroot /mnt pacman --noconfirm -S go
arch-chroot /mnt sudo -u ${username} git clone https://aur.archlinux.org/yay.git /home/${username}/yay
# Build (makepkg is not allowed to run as root)
arch-chroot /mnt bash -c \
  "cd /home/${username}/yay; sudo -u ${username} sudo -K; sudo -Su ${username} makepkg" <<EOF
${userpasswd}
EOF
# Install
arch-chroot /mnt bash -c \
  "pacman --noconfirm -U \$(find /home/${username}/yay -type f -name '*.pkg.tar.xz')"
arch-chroot /mnt rm -rf /home/${username}/yay
# Remove dependencies
arch-chroot /mnt pacman --noconfirm -Rns go
# Configure
arch-chroot /mnt sudo -u ${username} yay --save --sudoloop

# Pacman wrapper (Powerpill)
arch-chroot /mnt bash -c \
  "sudo -u ${username} sudo -K; sudo -u ${username} yay --sudoflags -S --noconfirm -S powerpill" <<EOF
${userpasswd}
EOF
# Using rsync
rsyncservers=$(reflector -p rsync -c JP -c KR -c HK -c TW | sed -e '/^#/d' -e '/^$/d')
pacman --noconfirm -S jq
jq ".rsync.servers = [$(echo "${rsyncservers}" | sed -e 's/^\(.*\)$/\"\1\"/g' | paste -sd ',')]" \
  /mnt/etc/powerpill/powerpill.json >./powerpill.json
mv -f ./powerpill.json /mnt/etc/powerpill/powerpill.json
# Troubleshooting
sed -e 's/^\(SigLevel.*\)$/#\1\nSigLevel = PackageRequired/' \
  -i /mnt/etc/pacman.conf
# Avoiding multiple definition errors
sed -e 's/^\(LDFLAGS="\(.*\)"\)$/#\1\nLDFLAGS="\2,-z,muldefs"/' \
  -i /mnt/etc/makepkg.conf
# Use Powerpill instead of Pacman inside Yay
arch-chroot /mnt sudo -u ${username} yay --save --pacman powerpill

# Clock synchronization (systemd-timesyncd)
cat <<EOF >>/mnt/etc/systemd/timesyncd.conf
NTP=0.arch.pool.ntp.org 1.arch.pool.ntp.org 2.arch.pool.ntp.org 3.arch.pool.ntp.org
FallbackNTP=0.pool.ntp.org 1.pool.ntp.org 0.fr.pool.ntp.org
EOF
arch-chroot /mnt timedatectl set-ntp true

# Unmount all the partitions
umount -R /mnt

#################### FINISH ####################

printf "\n\n"
printf "+--------------------------+\n"
printf "| ${GREEN}Successfully Installed!!${RESET} |\n"
printf "+--------------------------+\n\n\n"

exit
