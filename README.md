# Arch Linux Install Scripts


## Requirement

- UEFI
- Newer PC (if old, you may need to install additional drivers)


## All Scripts

### `install.sh`

- Partition
- Format the partitions
- Install essential packages
- Network configuration (NetrowkManager)
- Install the EFI boot manager (systemd-boot)

|  Mount point  |  Partition  |  Partition type  |  Size  |  Format  |
| ---- | ---- | ---- | ---- | ---- |
| /mnt/boot | first (e.g. /dev/sda1) | EFI system partition | 512 MiB | FAT32 |
| /mnt | second | Linux | Remainder of the device | Ext4 |

For swap space, you can use a swap file (`post_install.sh`).

### `post_install.sh`

- Create a swap file (systemd-swap)
- Add a sudo user (wheel group)
- Utilize multiple cores on compression for pacman
- Install an AUR helper (yay)

### `gui_xfce.sh`

- Install a display server (Xorg) 
- Install a display manager (LightDM)
- Install a desktop environment (Xfce)
- Install tools for sound management (ALSA, PulseAudio)
- 日本語入力の設定 (Fcitx, Mozc)
  - 左Altで英字入力、右Altで日本語入力
- Install a web browser (FireFox)
- Install pacman wrapper (Powerpill)

## Usage

### Install Base System

`install.sh`

This script should be run in the live environment.
You need to be connedted to the Internet using `wifi-menu` or other tools before running.

```sh
$ curl -O https://raw.githubusercontent.com/utatatata/sushi/master/install.sh
$ chmod +x install.sh
$ ./install.sh

$ reboot
```

### Additional Settings

`post_install.sh`

After running `install.sh` and reboot, you can run this script in the installed system.
Log in as root user, connect to the Internet, and run this script.

```sh
$ curl -O https://raw.githubusercontent.com/utatatata/sushi/master/post_install.sh
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

Use the following commands to find out which video driver you want to use in advance.
[Xorg - ArchWiki](https://wiki.archlinux.org/index.php/Xorg#Driver_installation)

```sh
lspci | grep -e VGA -e 3D
```

```sh
$ curl -O https://raw.githubusercontent.com/utatatata/sushi/master/gui_xfce.sh
$ chmod +x gui_xfce.sh
$ ./gui_xfce.sh

$ rm gui_xfce.sh
$ reboot
```
