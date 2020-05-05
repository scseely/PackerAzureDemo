#!/bin/bash

# Run this script as root via sudo. If you don't, most of the script fails.
# This script makes the following assumptions:
# 1. The VHD starts with 2 partitions on /dev/sda
# 2. The os-disk-size was set to 128 GB
# 3. The LVM should use all remaining space (~95GB)
# 
# So, if you use this script, validate these assumptions. If you use
# the script blindly, bad things may happen.

# set the directory to map all the new space to
map_dir=/usr/mydata

# This bit assumes that the empty space is on sda3. If that's wrong, 
# change the device_id.
device_id=/dev/sda
device_num=3
device_path=$(echo $device_id$device_num)

# First, determine what the last block is on the device.
last_block=$(fdisk -l $device_id | grep 'sda2' | awk '{ print $3 }')

# Create the string to start the new partition on the next 
# blank spot. 
new_block=$(($last_block + 1))
new_block_string=$(echo "$new_block"s)

# Create the partition
parted -a optimal -s $device_id mkpart primary $new_block_string 100%

# Set the partition as an LVM volume
parted $device_id set $device_num lvm on

# Create the physical volume
pvcreate $device_path

# Extend rootvg to this volume
# This bit exercises assumption 1
vgextend rootvg $device_path
lvcreate -L 95GB -n mydatalv rootvg

# Set the file system
mkfs -t ext4 /dev/rootvg/mydatalv

# Create the mount point
mkdir $map_dir

# Note: echoing directly to /etc/fstab did not work, so we do it locally.
cp /etc/fstab .
chmod 666 fstab

# Edit the fstab file so that things mount every time.
echo -e "/dev/mapper/rootvg-mydatalv\t$map_dir\text4\tdefaults\t0 0" >> fstab

# Copy the edits back
chmod 644 fstab
cp fstab /etc/fstab
rm fstab

# Extra, if needed: make sure the LVM is mounted, it will auto-mount on reboot
mount $map_dir