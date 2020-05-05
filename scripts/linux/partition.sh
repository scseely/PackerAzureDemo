last_block=$(sudo fdisk -l /dev/sda | grep 'sda2' | awk '{ print $3 }')
            
# Create the string to start the new partition on the next 
# blank spot. 
new_block=$(($last_block + 1))
new_block_string=$(echo "$new_block"s)

# Create the partition
sudo parted -a optimal -s /dev/sda mkpart primary $new_block_string 100%

# Set the partition as an LVM volume
sudo parted /dev/sda set 3 lvm on

# Create the physical volume
sudo pvcreate /dev/sda3

# Extend rootvg to this volume
sudo vgextend rootvg /dev/sda3
sudo lvcreate -L 95GB -n fioranolv rootvg

# Set the file system
sudo mkfs -t ext4 /dev/rootvg/fioranolv

# Create the mount point
sudo mkdir /var/fiorano

# Note: echoing directly to /etc/fstab did not work, so we do it locally.
sudo cp /etc/fstab .
sudo chmod 666 fstab

# Edit the fstab file so that things mount every time.
sudo echo -e "/dev/mapper/rootvg-fioranolv\t/var/fiorano\text4\tdefaults\t0 0" >> fstab

# Copy the edits back
sudo chmod 644 fstab
sudo cp fstab /etc/fstab
sudo rm fstab

# Extra, if needed: make sure the LVM is mounted, it will auto-mount on reboot
sudo mount /var/fiorano