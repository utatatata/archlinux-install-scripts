# Arch Linux Install Scripts

Scripts for Arch Linux installation

## Requirement

- UEFI
- New PC as possible (if old, you may need to install additional drivers)
- Standard devices (similarly, you may need additional drivers)
- Standard US keyboard

## All Scripts

### `base.sh`

- Partition the disks
- Format the partitions
- Install essential packages
- Swap file (systemd-swap)
- Network configuration (NetworkManager)
- Boot loader (systemd-boot)
- Add a sudo user (wheel group)
- Mirrors (Reflector)
- Utilizing multiple cores for makepkg
- AUR helper (Yay)
- Pacman wrapper (Powerpill)
- Clock synchronization (systemd-timesyncd)

| Mount point | Partition              | Partition type GUID                                         | Size                    | File system |
| ----------- | ---------------------- | ----------------------------------------------------------- | ----------------------- | ----------- |
| /mnt/boot   | first (e.g. /dev/sda1) | C12A7328-F81F-11D2-BA4B-00A0C93EC93B: EFI system partition  | 260 MiB                 | FAT32       |
| /mnt        | second                 | 4F68BCE3-E8CD-4DB1-96E7-FBCAF984B709: Linux x86-64 root (/) | 32 GiB                  | Ext4        |
| /mnt/home   | third                  | 933AC7E1-2EB4-4F13-B844-0E14E2AEF915: Linux /home           | Remainder of the device | Ext4        |

#### Available environment variables

- ALIS_INSTALL_DEVICE_PATH
  - e.g. `/dev/sda`
- ALIS_HOSTNAME
- ALIS_CPU_MANUFACTURER
  - `intel` or `amd`
- ALIS_ROOT_PASSWD
- ALIS_USER_NAME
- ALIS_USER_PASSWD

#### References

- [Installation guide - ArchWiki](https://wiki.archlinux.org/index.php/installation_guide)
  - [Partitioning - ArchWiki](https://wiki.archlinux.org/index.php/Partitioning)
    - [Partitioning#Example_layouts - ArchWik](https://wiki.archlinux.org/index.php/Partitioning#Example_layouts)
    - [GPT fdisk - ArchWiki](https://wiki.archlinux.org/index.php/GPT_fdisk)
  - [EFI system partition - ArchWiki](https://wiki.archlinux.org/index.php/EFI_system_partition)
  - [Mirrors - ArchWiki](https://wiki.archlinux.org/index.php/Mirrors)
    - [Reflector - ArchWiki](https://wiki.archlinux.org/index.php/Reflector)
  - [Swap#Automated - ArchWik](https://wiki.archlinux.org/index.php/Swap#Automated)
  - [NetworkManager - ArchWiki](https://wiki.archlinux.org/index.php/NetworkManager)
  - [Arch boot process#Boot_loader - ArchWiki](https://wiki.archlinux.org/index.php/Arch_boot_process#Boot_loader)
    - [systemd-boot - ArchWiki](https://wiki.archlinux.org/index.php/Systemd-boot)
      - [Microcode - ArchWiki#systemd-boot](https://wiki.archlinux.org/index.php/Microcode#systemd-boot)
- [General recommendations - ArchWiki](https://wiki.archlinux.org/index.php/General_recommendations)
  - [Users and groups#User_management - ArchWiki](https://wiki.archlinux.org/index.php/Users_and_groups#User_management)
  - [Sudo - ArchWiki](https://wiki.archlinux.org/index.php/Sudo)
  - [Mirrors - ArchWiki](https://wiki.archlinux.org/index.php/Mirrors)
    - [Reflector - ArchWiki](https://wiki.archlinux.org/index.php/Reflector)
  - [Arch User Repository - ArchWiki](https://wiki.archlinux.org/index.php/Arch_User_Repository)
    - [makepkg - ArchWiki](https://wiki.archlinux.org/index.php/Makepkg)
      - [makepkg - ArchWiki#Improving_compile_times](https://wiki.archlinux.org/index.php/Makepkg#Improving_compile_times)
      - [makepkg - ArchWiki#Utilizing_multiple_cores_on_compression](https://wiki.archlinux.org/index.php/Makepkg#Utilizing_multiple_cores_on_compression)
    - [AUR helpers - ArchWiki](https://wiki.archlinux.org/index.php/AUR_helpers)
      - [GitHub - Jguer/yay: Yet another Yogurt - An AUR Helper written in Go](https://github.com/Jguer/yay)
  - [pacman/Tips and tricks - ArchWiki](https://wiki.archlinux.org/index.php/Pacman/Tips_and_tricks)
    - [Powerpill - ArchWiki](https://wiki.archlinux.org/index.php/Powerpill)
  - [System time#Time_synchronization - ArchWiki](https://wiki.archlinux.org/index.php/System_time#Time_synchronization)
    - [systemd-timesyncd - ArchWiki](https://wiki.archlinux.org/index.php/Systemd-timesyncd)

### `gui-xfce.sh`

- Display server (Xorg)
- Display manager (LightDM)
- Desktop environment (Xfce)
- Tools for sound management (ALSA, PulseAudio)
- 日本語入力 (Fcitx, Mozc)
  - 左 Alt で英字入力、右 Alt で日本語入力
  - システムロケールは英語
- Web browser (FireFox)

#### References

- [General recommendations - ArchWiki](https://wiki.archlinux.org/index.php/General_recommendations)
  - [Xorg - ArchWiki](https://wiki.archlinux.org/index.php/Xorg)
  - [Display manager - ArchWiki](https://wiki.archlinux.org/index.php/Display_manager)
    - [LightDM - ArchWiki](https://wiki.archlinux.org/index.php/LightDM)
  - [Desktop environment - ArchWiki](https://wiki.archlinux.org/index.php/Desktop_environment)
    - [Xfce - ArchWiki](https://wiki.archlinux.org/index.php/Xfce)
  - [Sound system - ArchWiki](https://wiki.archlinux.org/index.php/Sound_system)
    - [Advanced Linux Sound Architecture - ArchWiki](https://wiki.archlinux.org/index.php/Advanced_Linux_Sound_Architecture)
    - [PulseAudio - ArchWiki](https://wiki.archlinux.org/index.php/PulseAudio)
  - [Localization/Japanese - ArchWiki](https://wiki.archlinux.org/index.php/Localization/Japanese)
    - [Fcitx - ArchWiki](https://wiki.archlinux.org/index.php/Fcitx)
    - [Mozc - ArchWiki](https://wiki.archlinux.org/index.php/Mozc)

### `gui-i3.sh`

- Display server (Xorg)
- Official configuration utility to the RandR (xrandr)
- Display manager (LightDM)
- Window manager (i3)
- Status bar (Polybar)
- Terminal emulator (Alacritty)
- Launcher (Rofi)
- Image viewer (Feh)
- File manager (SpaceFM)
- Tools for sound management (ALSA, PulseAudio)
- 日本語入力 (Fcitx, Mozc)
  - 左 Alt で英字入力、右 Alt で日本語入力
- Web browser (FireFox)
- Shell (fish)
  - Fisher
  - Powerline (bobthefish)

#### Available environment variables

#### References

- []()
- []()

## Usage

### Install Base System

`base.sh`

This script should be run in the live environment.
If you are using a wireless connection, you need to be connected to the Internet using `wifi-menu` or other tools before running.

```sh
$ curl -O https://raw.githubusercontent.com/utatatata/archlinux-install-scripts/master/base.sh
$ chmod +x base.sh
$ ./base.sh

$ reboot
```

### GUI

`gui-*.sh` (`gui-xfce.sh`, `gui-i3.sh`)

After running `base.sh` and rebooting, you can run this script in the installed system.
Log in a user other than root, connect to the Internet using NetworkManager (`nmtui` is easy), and run this script.

Run the following commands and you can find out which video driver you want to use in advance.

[Xorg#Driver_installation - ArchWiki](https://wiki.archlinux.org/index.php/Xorg#Driver_installation)

```sh
lspci | grep -e VGA -e 3D
```

```sh
$ curl -O https://raw.githubusercontent.com/utatatata/archlinux-install-scripts/master/gui-*.sh
$ chmod +x gui-*.sh
$ ./gui-*.sh

$ rm gui-*.sh
$ sudo reboot
```
