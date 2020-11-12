# timeshift-autosnap-apt
Timeshift auto-snapshot script which runs before any `apt update|install|remove` command using a `DPkg::Pre-Invoke` hook in APT. Works best in `BTRFS` mode, but `RSYNC` is also supported (might be slow though).

## Features
*  This script is a fork of [timeshift-autosnap](https://gitlab.com/gobonja/timeshift-autosnap) from the [AUR](https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=timeshift-autosnap), but adapted for usage with the APT package manager of Debian or Ubuntu based systems.
*  Creates [Timeshift](https://github.com/teejee2008/timeshift) snapshots with a unique (customizable) comment.
*  Keeps only a certain number of snapshots created using this script.
*  Deletes old snapshots which are created using this script.
*  Makes a copy with RSYNC of `/boot` and `/boot/efi` to `/boot.backup` before the call to Timeshift for more flexible restore options.
*  Can be manually executed by running `sudo timeshift-autosnap-apt`.
*  Autosnaphots can be temporarily skipped by setting "SKIP_AUTOSNAP" environment variable (e.g. `sudo SKIP_AUTOSNAP= apt upgrade`)
*  Supports [grub-btrfs](https://github.com/Antynea/grub-btrfs) which automatically creates boot menu entries of all your btrfs snapshots into grub.
*  For a tutorial how to use this script in production to easily rollback your system, see [System Recovery with Timeshift](https://mutschler.eu/linux/install-guides/).

## Installation
#### Install dependencies
```bash
sudo apt install git make
```
#### Install and configure Timeshift
```bash
sudo apt install timeshift
```
Open Timeshift and configure it either using btrfs or rsync. I recommend using btrfs as a filesystem for this, see my [btrfs installation guides](https://mutschler.eu/linux/install-guides/) for Pop!_OS, Ubuntu, and Manjaro.

#### Main installation
Clone this repository and install the script and configuration file with make:
```bash
git clone https://github.com/wmutschl/timeshift-autosnap-apt.git /home/$USER/timeshift-autosnap-apt
cd /home/$USER/timeshift-autosnap-apt
sudo make install
```
After this, make changes to the configuration file:
```bash
sudo nano /etc/timeshift-autosnap-apt.conf
```
For example, if you don't have a dedicated `/boot` partition, then you should set `snapshotBoot=false`. This will still make a copy of `/boot/efi`.

#### Optionally, install `grub-btrfs`
[grub-btrfs](https://github.com/Antynea/grub-btrfs) is a great package which will include all btrfs snapshots into the Grub menu. Clone and install it:
```bash
git clone https://github.com/Antynea/grub-btrfs.git /home/$USER/grub-btrfs
cd /home/$USER/grub-btrfs
sudo make install
```
By default the snapshots are displayed as "Arch Linux Snapshots", you can adapt this in `/etc/default/grub-btrfs/config`.

#### Configuration
The configuration file is located in `/etc/timeshift-autosnap-apt.conf`. You can set the following options:
*  `snapshotBoot`: If set to **true** /boot folder will be cloned with rsync into /boot.backup before the call to Timeshift. Note that this will not include the /boot/efi folder. Default: **true**
*  `snapshotEFI`: If set to **true** /boot/efi folder will be cloned with rsync into /boot.backup/efi before the call to Timeshift. Default: **true**
*  `skipAutosnap`: If set to **true** script won't be executed. Default: **false**.
*  `deleteSnapshots`: If set to **false** old snapshots won't be deleted. Default: **true**
*  `maxSnapshots`: Defines **maximum** number of old snapshots to keep. Default: **3**
*  `updateGrub`: If set to **false** GRUB entries won't be generated. Only if grub-btrfs is installed. Default: **true**
*  `snapshotDescription` Defines **string** used to distinguish snapshots created using timeshift-autosnap-apt. Default: **{timeshift-autosnap-apt} {created before call to APT}**

## Test functionality
To test the functionality, simply run
```bash
sudo timeshift-autosnap-apt
``` 
Or try (re)installing some package `maxSnapshots` number of times, e.g.
```bash
sudo apt install --reinstall rolldice
sudo apt install --reinstall rolldice
sudo apt install --reinstall rolldice
```
You should see output for BTRFS similar to
```bash
# Using system disk as snapshot device for creating snapshots in BTRFS mode
#
# /dev/dm-1 is mounted at: /run/timeshift/backup, options: rw,relatime,compress=zstd:3,ssd,space_cache,commit=120,subvolid=5,subvol=/
#
# Creating new backup...(BTRFS)
# Saving to device: /dev/dm-1, mounted at path: /run/timeshift/backup
# Created directory: /run/timeshift/backup/timeshift-btrfs/snapshots/2020-04-29_09-46-30
# Created subvolume snapshot: /run/timeshift/backup/timeshift-btrfs/snapshots/2020-04-29_09-46-30/@
# Created subvolume snapshot: /run/timeshift/backup/timeshift-btrfs/snapshots/2020-04-29_09-46-30/@home
# Created control file: /run/timeshift/backup/timeshift-btrfs/snapshots/2020-04-29_09-46-30/info.json
# BTRFS Snapshot saved successfully (0s)
# Tagged snapshot '2020-04-29_09-46-30': ondemand
# --------------------------------------------------------------------------
```
or for RSYNC similar to
```bash
# /dev/vdb1 is mounted at: /run/timeshift/backup, options: rw,relatime
# ------------------------------------------------------------------------------
# Creating new snapshot...(RSYNC)
# Saving to device: /dev/vdb1, mounted at path: /run/timeshift/backup
# Synching files with rsync...
# Created control file: /run/timeshift/backup/timeshift/snapshots/2020-04-29_10-25-35/info.json
# RSYNC Snapshot saved successfully (6s)
# Tagged snapshot '2020-04-29_10-25-35': ondemand
------------------------------------------------------------------------------
```

Open timeshift and see whether there are `maxSnapshots` packages:
![Timeshift](timeshift-autosnap-apt.png)

Close timeshift and reinstall the package another time and you should see that the first package is now deleted:
```bash
sudo apt install --reinstall rolldice
#
# Using system disk as snapshot device for creating snapshots in BTRFS mode
# /dev/dm-1 is mounted at: /run/timeshift/backup, options: rw,relatime,compress=zstd:3,ssd,space_cache,commit=120,subvolid=5,subvol=/
# Creating new backup...(BTRFS)
# Saving to device: /dev/dm-1, mounted at path: /run/timeshift/backup
# Created directory: /run/timeshift/backup/timeshift-btrfs/snapshots/2020-04-29_09-53-25
# Created subvolume snapshot: /run/timeshift/backup/timeshift-btrfs/snapshots/2020-04-29_09-53-25/@
# Created subvolume snapshot: /run/timeshift/backup/timeshift-btrfs/snapshots/2020-04-29_09-53-25/@home
# Created control file: /run/timeshift/backup/timeshift-btrfs/snapshots/2020-04-29_09-53-25/info.json
# BTRFS Snapshot saved successfully (0s)
# Tagged snapshot '2020-04-29_09-53-25': ondemand
# ------------------------------------------------------------------------------
# 
# /dev/dm-1 is mounted at: /run/timeshift/backup, options: rw,relatime,compress=zstd:3,ssd,space_cache,commit=120,subvolid=5,subvol=/
# 
# ------------------------------------------------------------------------------
# Removing snapshot: 2020-04-29_09-46-30
# Deleting subvolume: @home (Id:662)
# Deleted subvolume: @home (Id:662)
# 
# Destroying qgroup: 0/662
# Destroyed qgroup: 0/662
# 
# Deleting subvolume: @ (Id:661)
# Deleted subvolume: @ (Id:661)
# 
# Destroying qgroup: 0/661
# Destroyed qgroup: 0/661
# 
# Deleted directory: /run/timeshift/backup/timeshift-btrfs/snapshots/2020-04-29_09-46-30
# Removed snapshot: 2020-04-29_09-46-30
# ------------------------------------------------------------------------------
```
or for RSYNC:

```bash
# /dev/vdb1 is mounted at: /run/timeshift/backup, options: rw,relatime
# 
# ------------------------------------------------------------------------------
# Creating new snapshot...(RSYNC)
# Saving to device: /dev/vdb1, mounted at path: /run/timeshift/backup
# Linking from snapshot: 2020-04-29_10-25-15
# Synching files with rsync...
# Created control file: /run/timeshift/backup/timeshift/snapshots/2020-04-29_10-25-35/info.json
# RSYNC Snapshot saved successfully (6s)
# Tagged snapshot '2020-04-29_10-25-35': ondemand
# ------------------------------------------------------------------------------
# 
# /dev/vdb1 is mounted at: /run/timeshift/backup, options: rw,relatime
# 
# ------------------------------------------------------------------------------
# Removing '2020-04-29_10-24-35'...
# Removed '2020-04-29_10-24-35'                                                   
# ------------------------------------------------------------------------------
```
---

### Uninstallation
```
cd /home/$USER/timeshift-autosnap-apt
sudo make uninstall
```

---

## Ideas and contributions
- [x] Ask to be included into official Timeshift package, [status pending](https://github.com/teejee2008/timeshift/issues/595).
- [x] rsync /boot and /boot/efi to filesystem for more flexibility when restoring failed kernel updates (tested on Ubuntu 20.04 and Pop!_OS 20.04)
- [x] Check and adapt [grub-btrfs](https://github.com/Antynea/grub-btrfs) for compatibility with Debian-based systems to automatically create menu entries into grub (tested on Ubuntu 20.04).
- [ ] Make rsync of /boot and /boot/efi dependent on btrfs only, provide "auto" model, i.e. check whether efi or legacy boot and then rsync into filesystem
- [ ] Add prompt or pause if user wants to trigger timeshift-autosnap-apt or add optional timeout between snapshots
- [ ] Provide better description of snapshots based on call to apt

**All new ideas and contributors are much appreciated and welcome, just open an issue for that!**
