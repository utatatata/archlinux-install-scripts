#!/usr/bin/env bash

set -eu

# ANSI escape code (https://en.wikipedia.org/wiki/ANSI_escape_code)
prefix="\x1b["
suffix="m"
RESET="${prefix}${suffix}"
RED="${prefix}31${suffix}"
GREEN="${prefix}32${suffix}"
CYAN="${prefix}36${suffix}"

error () {
  printf "${RED}error${RESET}: ${1}\n"
}


#################### TITLE  ####################
printf "\n${GREEN}Arch Linux Install Script (Base System)${RESET}\n\n\n"


#################### Install device path ####################

devices=$(lsblk -dlnpo NAME)
if [[ ! -v  ALIS_INSTALL_DEVICE_PATH ||
      "$(grep ^${ALIS_INSTALL_DEVICE_PATH}$ <<< ${devices})" = "" ]]; then
  while true; do
    read -ep "Install device path: "  ALIS_INSTALL_DEVICE_PATH

    if [[ "$(grep ^${ALIS_INSTALL_DEVICE_PATH}$ <<< ${devices})" = "" ]]; then
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

if [[ ! -v ALIS_HOSTNAME ||
      "$ALIS_HOSTNAME" = "" ]]; then
  while true; do
    read -p "Host name: " ALIS_HOSTNAME

    if [[ "$ALIS_HOSTNAME" = "" ]]; then
      error "invalid value: hostname must not be empty"
      echo ""
    else
      break
    fi
  done

  echo ""
fi

hostname="$ALIS_HOSTNAME"


#################### Root passwd ####################

if [[ ! -v ALIS_ROOT_PASSWD ||
      "$ALIS_ROOT_PASSWD" = "" ]]; then
  while true; do
    read -sp "Root password: " rootpasswd1 && echo ""
    read -sp "Retype root password: " rootpasswd2 && echo ""

    if [[ ! "$rootpasswd1" = "$rootpasswd2" ]]; then
      error "passwords do not match"
      echo ""
    elif [[ "$rootpasswd1" = "" ]]; then
      error "invalid value: password must not be empty"
      echo ""
    else
      ALIS_ROOT_PASSWD=$rootpasswd1
      break
    fi
  done

  echo ""
fi

rootpasswd=$ALIS_ROOT_PASSWD


#################### INSTALL ####################

# Update the system clock
timedatectl set-ntp true

# Partition the disks
gdisk $devicepath <<EOF
o
y
n


+512M
EF00
n




w
y
EOF

partitions=$(lsblk -lnpo NAME $devicepath | tail -n+2)
efi=$(echo "$partitions" | head -n 1)
root=$(echo "$partitions" | tail -n 1 | head -n 1)

# Format the partitions
umount -R /mnt || true
mkfs.fat -F32 $efi
mkfs.ext4 -F $root

# Mount the file systems
mount $root /mnt
mkdir /mnt/boot
mount $efi /mnt/boot

# Select the mirrors
pacman -Sy
pacman --noconfirm -S reflector
reflector -p rsync -p https -p http -c JP -c KR -c HK -c TW --save /etc/pacman.d/mirrorlist

# Install essential packages
pacstrap /mnt base base-devel linux linux-firmware networkmanager wpa_supplicant nano vi vim man-db man-pages texinfo intel-ucode rsync reflector

# Automation for reflector
mkdir -p /mnt/etc/pacman.d/hooks
cat <<EOF > /mnt/etc/pacman.d/hooks/mirrorupgrade.hook
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
cat <<EOF > /mnt/etc/systemd/system/reflector.service
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

# Fstab
genfstab -U /mnt >> /mnt/etc/fstab

# After that, work in chroot

# Time zone
arch-chroot /mnt ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
arch-chroot /mnt hwclock --systohc

# Localization
localegen=$(cat /mnt/etc/locale.gen)
# Insert at the top
cat <<EOF > /mnt/etc/locale.gen
en_US.UTF-8 UTF-8
ja_JP.UTF-8 UTF-8
EOF
echo "$localegen" >> /mnt/etc/locale.gen
arch-chroot /mnt locale-gen
echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf

# Network configuration
echo $hostname > /mnt/etc/hostname
cat <<EOF >> /mnt/etc/hosts
127.0.0.1	localhost
::1		localhost
127.0.1.1	$hostname.localdomain	$hostname
EOF
arch-chroot /mnt systemctl enable NetworkManager

# Root password
arch-chroot /mnt passwd <<EOF
$rootpasswd
$rootpasswd
EOF

# Installing the EFI boot manager
arch-chroot /mnt bootctl --path=/boot install

# Loader configuration
cat <<EOF > /mnt/boot/loader/loader.conf
default  arch.conf
timeout  4
console-mode max
editor   no
EOF

# Adding loaders
cat <<EOF > /mnt/boot/loader/entries/arch.conf
title   Arch Linux
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options root=UUID=$(blkid -s UUID -o value $root) rw
EOF

# Automatic update
mkdir -p /mnt/etc/pacman.d/hooks
cat <<EOF > /mnt/etc/pacman.d/hooks/100-systemd-boot.hook
[Trigger]
Type = Package
Operation = Upgrade
Target = systemd

[Action]
Description = Updating systemd-boot
When = PostTransaction
Exec = /usr/bin/bootctl update
EOF

# Unmount all the partitions
umount -R /mnt


#################### FINISH ####################

printf "\n\n"
printf "+--------------------------+\n"
printf "| ${CYAN}Successfully Installed!!${RESET} |\n"
printf "+--------------------------+\n\n\n"

exit
