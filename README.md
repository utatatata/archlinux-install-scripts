# Arch Linux Install Scripts

## Usage

### Install base system

`install.sh`

This script should be run in the live environment.
You need to be connedted to the Internet using `wifi-menu` or other tools before running.

```sh
curl -O https://raw.githubusercontent.com/utatatata/sushi/master/install.sh
chmod +x install.sh
./install.sh
```

### Post install

`post_install.sh`

After running `install.sh` and reboot, you can run this script in the installed system.
Log in as root user, connect to the Internet, and run this script.

```sh
curl -O https://raw.githubusercontent.com/utatatata/sushi/master/post_install.sh
chmod +x post_install.sh
./post_install.sh
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
curl -O https://raw.githubusercontent.com/utatatata/sushi/master/gui_xfce.sh
chmod +x gui_xfce.sh
./gui_xfce.sh
```
