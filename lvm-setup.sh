echo "Updating LVM filters"
sudo sed -i -e 's/filter = \[ "a\/.*\/" \]/filter = \[ "r|\/dev\/sdb|", "r|\/dev\/disk\/*|", "r|\/dev\/block\/*|", "a|.*|" \]/g' /etc/lvm/lvm.conf


echo "Disabling LVM cache"
sudo sed -i -e 's/write_cache_state = 1/write_cache_state = 0/g' /etc/lvm/lvm.conf

# Remove all stale cache entries
echo "Removing stale LVM cache entries"
sudo rm /etc/lvm/cache/.cache
sudo touch /etc/lvm/cache/.cache

echo "Restarting Ram Disk"
sudo update-initramfs -u
