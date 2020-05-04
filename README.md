# timeshift-autosnap-apt
Timeshift auto-snapshot script which runs before `apt upgrade|install|remove` using a `DPkg::Pre-Invoke` hook in apt.

## Features
*  This scrips is a fork of [timeshift-autosnap](https://gitlab.com/gobonja/timeshift-autosnap) from the [AUR](https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=timeshift-autosnap) for Arch and Arch based distros but adapted for usage in Debian based systems which use apt as their package manager.
*  Creates [Timeshift](https://github.com/teejee2008/timeshift) snapshots with unique comment.
*  Deletes old snapshots which are created using this script.
*  Makes a copy of `/boot` and `/boot/efi` to `/boot.backup` before the call to timeshift for more secure restore options.
*  Can be manually executed by running `sudo timeshift-autosnap-apt` command.
*  Autosnaphot can be temporarily skipped by setting SKIP_AUTOSNAP environment variable (e.g. `sudo SKIP_AUTOSNAP= apt upgrade`)
*  Supports both `BTRFS` and `RSYNC` mode.
*  For a tutorial how to use this script in production to easily rollback your system, see [Pop!_OS 20.04 btrfs-luks disaster recovery and easy system rollback using Timeshift and timeshift-autosnap-apt](https://mutschler.eu/linux/install-guides/pop-os-btrfs-recovery/).

## Installation
If you haven't, first install Timeshift:
```bash
sudo apt install timeshift
```
Open Timeshift and configure it either using btrfs or rsync. I recommend using btrfs as a filesystem for this, see my [btrfs installation guides](https://mutschler.eu/linux/install-guides/) for Pop!_OS, Ubuntu, and Manjaro.

Clone the repository and run the following commands to copy the hook, bash script and configuration file.
```bash
git clone https://github.com/wmutschl/timeshift-autosnap-apt.git
cd timeshift-autosnap-apt
sudo cp 80-timeshift-autosnap-apt /etc/apt/apt.conf.d/80-timeshift-autosnap-apt
sudo chmod 644 /etc/apt/apt.conf.d/80-timeshift-autosnap-apt
sudo cp timeshift-autosnap-apt /usr/bin/timeshift-autosnap-apt
sudo chmod 755 /usr/bin/timeshift-autosnap-apt
sudo cp timeshift-autosnap-apt.conf /etc/timeshift-autosnap-apt.conf
sudo chmod 644 /etc/timeshift-autosnap-apt.conf
```
After this, optionally, make changes to the configuration file:
```bash
sudo nano /etc/timeshift-autosnap-apt.conf
```
For example, if you don't have a dedicated `/boot` partition, then you should set `snapshotBoot=false`.

## Configuration
The configuration file is located in `/etc/timeshift-autosnap-apt.conf`. You can set the following options:
*  `snapshotBoot`: If set to **true** /boot folder will be cloned into /boot.backup before the call to timeshift. Note that this will not include the /boot/efi folder. Default: **true**
*  `snapshotEFI`: If set to **true** /boot/efi folder will be cloned into /boot.backup/efi before the call to timeshift. Default: **true**
*  `skipAutosnap`: If set to **true** script won't be executed. Default: **false**.
*  `deleteSnapshots`: If set to **false** old snapshots won't be deleted. Default: **true**
*  `maxSnapshots`: Defines **maximum** number of old snapshots to keep. Default: **3**
*  `snapshotDescription` Defines **value** used to distinguish snapshots created using timeshift-autosnap-apt. Default: **{timeshift-autosnap-apt} {created before call to APT}**

## Test functionality
To test the functionality, try (re)installing some package `maxSnapshots` number of times, e.g.
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

## Ideas and contributions
- [x] Ask to be included into official Timeshift package, [status pending](https://github.com/teejee2008/timeshift/issues/595).
- [x] Copy /boot and /boot/efi to filesystem for better control option when restoring (tested on Pop!_OS)
- [ ] Check and adapt [grub-btrfs](https://github.com/Antynea/grub-btrfs) for compatibility with Debian-based systems and this script (test on Ubuntu) to automatically create menu entries into grub.

**All new ideas and contributors are welcomed, just open an issue for that!**

