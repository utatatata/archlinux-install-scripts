# Arch Linux Install Scripts

Scripts for Arch Linux installation

## Requirement

- UEFI
- New PC as possible (if old, you may need to install additional drivers)
- Standard devices (similarly, you may need additional drivers)

## All Scripts

### `base.sh`

- Partition
- Format the partitions
- Install essential packages
- Network configuration (NetworkManager)
- Install the EFI boot manager (systemd-boot)
- Create a swap file (systemd-swap)
- Add a sudo user (wheel group)
- Utilize multiple cores for makepkg
- Install an AUR helper (Yay)
- Pacman wrapper (Powerpill)
- Clock synchronization (systemd-timesyncd)

| Mount point | Partition              | Partition type       | Size                    | Format |
| ----------- | ---------------------- | -------------------- | ----------------------- | ------ |
| /mnt/boot   | first (e.g. /dev/sda1) | EFI system partition | 512 MiB                 | FAT32  |
| /mnt        | second                 | Linux                | Remainder of the device | Ext4   |

### `gui-xfce.sh`

- Display server (Xorg)
- Display manager (LightDM)
- Desktop environment (Xfce)
- Tools for sound management (ALSA, PulseAudio)
- 日本語入力 (Fcitx, Mozc)
  - 左 Alt で英字入力、右 Alt で日本語入力
- Web browser (FireFox)

### `gui-i3.sh`

- Display server (Xorg)
- Official configuration utility to the RandR
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

[Xorg - ArchWiki](https://wiki.archlinux.org/index.php/Xorg#Driver_installation)

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
