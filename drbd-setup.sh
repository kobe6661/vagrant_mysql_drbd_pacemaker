node=$(hostname)
node=$(echo $node)
echo "$node is active."


if [[ $node = "grizzly2" ]]; then
sudo scp /vagrant/mysql.res /etc/drbd.d/mysql.res


echo "Disabling DRBD autostart"
sudo update-rc.d drbd disable



echo "Creating DRBD Metadata"
yes yes | sudo drbdadm create-md mysql

echo "Add DRBD to Kernel Modules"
sudo modprobe drbd
sudo chmod a+w /etc/modules
sudo echo 'drbd' >> /etc/modules

echo "Attach DRBD device"
sudo drbdadm up mysql

sshpass -p "vagrant" ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t -t vagrant@grizzly1 <<EOF
echo "SSH into grizzly1"

sudo scp /vagrant/mysql.res /etc/drbd.d/mysql.res

echo "Disabling DRBD autostart"
sudo update-rc.d drbd disable

echo "Creating DRBD Metadata"
yes yes | sudo drbdadm create-md mysql

echo "Add DRBD to Kernel Modules"
sudo modprobe drbd
sudo chmod a+w /etc/modules
sudo echo 'drbd' >> /etc/modules

echo "Attach DRBD device"
sudo drbdadm up mysql
exit
EOF

sudo service drbd start


numLines=40
timeToSleep=5
sshpass -p "vagrant" ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t -t vagrant@grizzly1 <<EOF
echo "SSH into grizzly1"
sudo drbdadm -- --overwrite-data-of-peer primary mysql
sudo service drbd start
until tail -n $numLines /proc/drbd | grep -q "UpToDate/UpToDate"; do 
  echo -ne 'synchronizing. \r'
  sleep $timeToSleep
  echo -ne 'synchronizing.. \r'
  sleep $timeToSleep
  echo -ne 'synchronizing... \r'
  sleep $timeToSleep
done
echo "DRBD sync'ed."
sudo mkfs.xfs -f /dev/drbd0 && sudo pvcreate /dev/drbd0 && sudo vgcreate VG_PG /dev/drbd0 && sudo lvcreate -L 35000M -n LV_DATA VG_PG
sudo mkfs.xfs -d agcount=8 -f /dev/VG_PG/LV_DATA
exit
EOF

#sudo mkfs.xfs -f /dev/drbd0 && sudo pvcreate /dev/drbd0 && sudo vgcreate VG_PG /dev/drbd0 && sudo lvcreate -L 35000M -n LV_DATA VG_PG
#sudo mkfs.xfs -d agcount=8 /dev/VG_PG/LV_DATA
fi
