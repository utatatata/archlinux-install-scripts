# Arch Linux Install Scripts


## Requirement

- UEFI
- New PC as possible (if old, you may need to install additional drivers)
- Standard devices (similarly, you may need additional drivers)


## All Scripts

### `install.sh`

- Partition
- Format the partitions
- Install essential packages
- Network configuration (NetworkManager)
- Install the EFI boot manager (systemd-boot)

|  Mount point  |  Partition  |  Partition type  |  Size  |  Format  |
| ---- | ---- | ---- | ---- | ---- |
| /mnt/boot | first (e.g. /dev/sda1) | EFI system partition | 512 MiB | FAT32 |
| /mnt | second | Linux | Remainder of the device | Ext4 |

For swap space, you can use a swap file (`post_install.sh`).

### `post_install.sh`

- Create a swap file (systemd-swap)
- Add a sudo user (wheel group)
- Utilize multiple cores on compression for Pacman
- Install an AUR helper (Yay)

### `gui_xfce.sh`

- Display server (Xorg) 
- Display manager (LightDM)
- Desktop environment (Xfce)
- Install tools for sound management (ALSA, PulseAudio)
- 日本語入力 (Fcitx, Mozc)
  - 左Altで英字入力、右Altで日本語入力
- Web browser (FireFox)

## Usage

### Install Base System

`install.sh`

This script should be run in the live environment.
If you are using a wireless connection, you need to be connedted to the Internet using `wifi-menu` or other tools before running.

```sh
$ curl -O https://raw.githubusercontent.com/utatatata/archlinux-install-scripts/master/install.sh
$ chmod +x install.sh
$ ./install.sh

$ reboot
```

### Additional Settings

`post_install.sh`

After running `install.sh` and rebooting, you can run this script in the installed system.
Log in as root user, connect to the Internet using NetworkManager (`nmtui` is easy), and run this script.

```sh
$ curl -O https://raw.githubusercontent.com/utatatata/archlinux-install-scripts/master/post_install.sh
$ chmod +x post_install.sh
$ ./post_install.sh

$ rm post_install.sh
$ logout
```

### GUI

These scripts should be run in the installed system.
Please run it as a user other than root.

#### Xfce

`gui_xfce.sh`

Run the following commands and you can find out which video driver you want to use in advance.

[Xorg - ArchWiki](https://wiki.archlinux.org/index.php/Xorg#Driver_installation)

```sh
lspci | grep -e VGA -e 3D
```

```sh
$ curl -O https://raw.githubusercontent.com/utatatata/archlinux-install-scripts/master/gui_xfce.sh
$ chmod +x gui_xfce.sh
$ ./gui_xfce.sh

$ rm gui_xfce.sh
$ sudo reboot
```
