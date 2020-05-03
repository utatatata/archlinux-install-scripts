#!/usr/bin/env bash

set -eu

#################### Install device path ####################

if [[ ! -v  ALIS_INSTALL_DEVICE_PATH ]]; then
  printf "Install device path: "
  read ALIS_INSTALL_DEVICE_PATH
  echo ""
fi

# TODO: check device path

devicepath="${ALIS_INSTALL_DEVICE_PATH%/}"


#################### Device interface type ####################

if [[ ! -v ALIS_DEVICE_INTERFACE_TYPE || ! "$ALIS_DEVICE_INTERFACE_TYPE" =~ ^(SATA|NVMe)$ ]]; then
  echo "Device interface type"
  echo "   1) SATA 2) NVMe"

  while true; do
    echo ""
    printf "Enter a selection (default=1): "
    read select
    echo ""

    if [[ "$select" = "1" || "$select" = "" ]]; then
      ALIS_DEVICE_INTERFACE_TYPE="SATA"
      break
    elif  [[ "$select" = "2" ]]; then
      ALIS_DEVICE_INTERFACE_TYPE="NVMe"
      break
    else
      echo "error: invalid value: $select is not between 1 and 2"
    fi
  done
fi

if [[ "$ALIS_DEVICE_INTERFACE_TYPE" = "NVMe" ]]; then
  prefix="p"
else
  prefix=""
fi
efi=$devicepath$prefix"1"
root=$devicepath$prefix"2"


#################### Device interface type ####################

if [[ ! -v ALIS_HOSTNAME ]]; then
  printf "Host name: "
  read ALIS_HOSTNAME
  echo ""
fi

hostname="$ALIS_HOSTNAME"


#################### Root passwd ####################

if [[ ! -v ALIS_ROOT_PASSWD ]]; then
  while true; do
    echo ""
    printf "Root password: "
    read -s rootpasswd1
    echo ""
    printf "Retype root password: "
    read -s rootpasswd2
    echo ""
    if [[ "$rootpasswd1" = "$rootpasswd2" ]]; then
      ALIS_ROOT_PASSWD=rootpasswd1
      break
    else
      echo 'Sorry, passwords do not match.'
    fi
  done
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

# Format the partitions
umount -R /mnt && true
mkfs.fat -F32 $efi
mkfs.ext4 -F $root

# Mount the file systems
mount $root /mnt
mkdir /mnt/boot
mount $efi /mnt/boot

# Select the mirrors
mirrorlist=$(cat /etc/pacman.d/mirrorlist)
japanmirrorlist=$(grep --no-group-separator -A 1 'Japan' /etc/pacman.d/mirrorlist)
echo "$japanmirrorlist" > /etc/pacman.d/mirrorlist
echo "$mirrorlist" >> /etc/pacman.d/mirrorlist

# Install essential packages
pacstrap /mnt base base-devel linux linux-firmware networkmanager wpa_supplicant nano vi vim man-db man-pages texinfo intel-ucode

# Fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot
arch-chroot /mnt

# Time zone
ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
hwclock --systohc

# Localization
localegen=$(cat /etc/locale.gen)
cat <<EOF > /etc/locale.gen
en_US.UTF-8 UTF-8
ja_JP.UTF-8 UTF-8
EOF
echo "$localegen" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Network configuration
echo $hostname > /etc/hostname
cat <<EOF >> /etc/hosts
127.0.0.1	localhost
::1		localhost
127.0.1.1	$hostname.localdomain	$hostname
EOF
systemctl enable NetworkManager

# Root password
passwd <<EOF
$rootpasswd
$rootpasswd
EOF

# Installing the EFI boot manager
bootctl --path=/boot install

# Loader configuration
cat <<EOF > /boot/loader/loader.conf
default  arch.conf
timeout  4
console-mode max
editor   no
EOF

# Adding loaders
cat <<EOF > /boot/loader/entries/arch.conf
title   Arch Linux
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options root=UUID=$(blkid -s UUID -o value $root) rw
EOF

# Automatic update
mkdir -p /etc/pacman.d/hooks
cat <<EOF > /etc/pacman.d/hooks/100-systemd-boot.hook
[Trigger]
Type = Package
Operation = Upgrade
Target = systemd

[Action]
Description = Updating systemd-boot
When = PostTransaction
Exec = /usr/bin/bootctl update
EOF

# Finish
exit
umount -R /mnt
poweroff
