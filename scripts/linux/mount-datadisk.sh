#!/bin/bash

# Run this script as root via sudo. If you don't, most of the script fails.
# This script makes the following assumptions:
# Set a label on the device
# TODO: discover the device, don't hard code it. This flows 
#   through the rest of the script. Reason: a data disk may sometimes attach
#   as /dev/sda or other letters too. The assumptions in this sample are bad 
#   for production.
parted /dev/sdc mklabel msdos

# Create the partition
parted -a optimal -s /dev/sdc mkpart primary 1 100%

# Set the partition as an LVM volume
parted /dev/sdc set 1 lvm on

# Create the physical volume
pvcreate /dev/sdc1

# Extend rootvg to this volume
vgextend rootvg /dev/sdc1
lvcreate -L 127GB -n datavol rootvg

# Set the file system
mkfs -t ext4 /dev/rootvg/datavol

# Create the mount point
mkdir /var/datavol

# Note: echoing directly to /etc/fstab did not work, so we do it locally.
cp /etc/fstab .
chmod 666 fstab

# Get blkid of rootvg-datavols
datavol=$(blkid | grep 'rootvg-datavol')
startuuid=$(echo $datavol | \grep -aob '"' | head -n1 | cut -d: -f1)
enduuid=$(echo $datavol | \grep -aob '"' | head -n2 | tail -n1 | cut -d: -f1)
let "startuuid = $startuuid +1"
let "enduuid = $enduuid - $startuuid"
blockid=$(echo ${datavol:$startuuid:$enduuid})

# Edit the fstab file so that things mount every time.
echo -e "UUID=$blockid\t/var/datavol\text4\tdefaults,nofail\t1" >> fstab

# Copy the edits back
chmod 644 fstab
cp fstab /etc/fstab
rm fstab

# Extra, if needed: make sure the LVM is mounted, it will auto-mount on reboot
mount /var/datavol

