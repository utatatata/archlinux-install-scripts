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
print_cyan "\nArch Linux Install Script (Base System)\n\n\n"

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
sgdisk -n 1::+300M -c 1:"EFI system partition" \
  -t 1:C12A7328-F81F-11D2-BA4B-00A0C93EC93B \
  ${devicepath}
sgdisk -n 2:: -c 2:"Linux x86-64 root (/)" \
  -t 2:4F68BCE3-E8CD-4DB1-96E7-FBCAF984B709 \
  ${devicepath}

partitions=$(lsblk -lnpo NAME ${devicepath} | tail -n+2)
esp=$(echo "${partitions}" | head -n 1)
root=$(echo "${partitions}" | tail -n 1)

# Format the partitions
mkfs.fat -F 32 ${esp} -n "esp"
mkfs.ext4 -F ${root} -L "root"

# Mount the file systems
mount ${root} /mnt
mount --mkdir ${esp} /mnt/boot

# Install essential packages
pacstrap /mnt \
  base base-devel linux linux-firmware \
  networkmanager \
  vi gvim \ # clipboard not working in vim
  man-db man-pages texinfo \
  git

# Fstab
genfstab -U /mnt >>/mnt/etc/fstab

# After that, work in chroot
# Caution: `arch-chroot </path/to/new/root>` invokes bash by default,
#           but exit cannot be used to get out of bash in a shell script
#           So, in the following, each command is executed using arch-chroot

# Time zone
arch-chroot /mnt ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
arch-chroot /mnt hwclock --systohc

# Localization
sed -e 's/^#\(en_US.UTF-8 UTF-8\)$/\1/' \
    -e 's/^#\(ja_JP.UTF-8 UTF-8\)$/\1/' \
    -i /mnt/etc/locale.gen
arch-chroot /mnt locale-gen
echo "LANG=en_US.UTF-8" >/mnt/etc/locale.conf

# Network configuration (NetworkManager)
echo ${hostname} >/mnt/etc/hostname
arch-chroot /mnt systemctl enable NetworkManager

# Root password
arch-chroot /mnt passwd <<EOF
${rootpasswd}
${rootpasswd}
EOF

# Boot loader (GRUB)
arch-chroot /mnt pacman --noconfirm -S grub efibootmgr
arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
# Microcode
arch-chroot /mnt pacman --noconfirm -S ${cpu}-ucode
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

# User management
# Adding a user
arch-chroot /mnt useradd -m -G wheel -s /bin/bash ${username}
arch-chroot /mnt passwd ${username} <<EOF
${userpasswd}
${userpasswd}
EOF

# Privilege elevation (sudo)
cp /mnt/etc/sudoers ./sudoers
sed -e 's/^# \(%wheel ALL=(ALL:ALL) ALL\)$/\1/' \
  -i ./sudoers
visudo -qcf ./sudoers
if [[ "$?" = "0" ]]; then
  mv -f ./sudoers /mnt/etc/sudoers
else
  printf "\n\n\n"
  error "Failed to edit /etc/sudoers"
  exit 1
fi

# Pacman configuration
sed -e 's/^#\(ParallelDownloads = 5\)$/\1/' \
  -i /mnt/etc/pacman.conf

# Improving compile times for makepkg
sed -e "s/^\(#MAKEFLAGS=.*\)\$/\1\nMAKEFLAGS=\"-j$(nproc)\"/" \
  -i /mnt/etc/makepkg.conf
# Utilizing multiple cores for makepkg
arch-chroot /mnt pacman --noconfirm -S pigz pbzip2
sed -e 's/\(COMPRESSXZ=(xz -c -z -)\)/\1\nCOMPRESSXZ=(xz -c -z - --threads=0)/' \
  -e 's/\(COMPRESSGZ=(gzip -c -f -n)\)/\1\nCOMPRESSGZ=(pigz -c -f -n)/' \
  -e 's/\(COMPRESSBZ2=(bzip2 -c -f)\)/\1\nCOMPRESSBZ2=(pbzip2 -c -f)/' \
  -e 's/\(COMPRESSZST=(zstd -c -z -q -)\)/\1\nCOMPRESSZST=(zstd -c -z -q - --threads=0)/' \
  -i /mnt/etc/makepkg.conf

# AUR helper (Yay)
yaydir=/home/${username}/yay
# Clone sources
arch-chroot /mnt sudo -u ${username} git clone https://aur.archlinux.org/yay-bin.git $yaydir
# Build
# Since 'makepkg -si' uses sudo internally and is not interactive, it does its internal processing separately.
arch-chroot /mnt bash -c \
  "cd $yaydir && sudo -u ${username} makepkg"
# Install and setup
arch-chroot /mnt bash -c \
  "pacman --noconfirm -U \$(find $yaydir -type f -name '*.pkg*') && rm -rf $yaydir"
arch-chroot /mnt sudo -u ${username} yay --sudoflags -S -Syy <<EOF
${userpasswd}
EOF

# Clock synchronization (systemd-timesyncd)
sed -e 's/\(#NTP=\)/\1\nNTP=0.arch.pool.ntp.org 1.arch.pool.ntp.org 2.arch.pool.ntp.org 3.arch.pool.ntp.org/' \
    -e 's/\(^#FallbackNTP=.*$\)/\1\nFallbackNTP=0.pool.ntp.org 1.pool.ntp.org 0.fr.pool.ntp.org/' \
    -i /mnt/etc/systemd/timesyncd.conf

# Swap file
arch-chroot /mnt echo 0 > /sys/module/zswap/parameters/enabled
arch-chroot /mnt pacman --noconfirm -S zram-generator
cat <<EOF >/mnt/etc/systemd/zram-generator.conf
[zram0]
zram-size = ram
compression-algorithm = zstd
swap-priority = 100
fs-type = swap
EOF
arch-chroot /mnt systemctl enable systemd-zram-setup@zram0

# Unmount all the partitions
umount -R /mnt

#################### FINISH ####################

printf "\n\n"
printf      "+--------------------------+\n"
print_green "| Successfully Installed!! |\n"
printf      "+--------------------------+\n\n\n"

exit
