node=$(hostname)
node=$(echo $node)
echo "$node is active."


if [[ $node = "grizzly2" ]]; then

sudo update-rc.d corosync enable
sudo sed -i 's/=no/=yes/' /etc/default/corosync
sudo scp /vagrant/corosync.conf /etc/corosync/corosync.conf
export ais_port=5405
export ais_mcast=239.255.42.1
export ais_addr=`ip addr | grep "inet " | tail -n 1 | awk '{print $4}' | sed s/255/0/`

echo "Restarting Interfaces"
sudo ifdown eth1 && sudo ifup eth1
sudo ifdown eth2 && sudo ifup eth2

if [[ $? = "0" ]]; then
echo "Successfully restarted.";
else
echo "No success.";
fi

sshpass -p "vagrant" ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t -t vagrant@grizzly1 <<EOF
echo "SSH into grizzly1"
sudo update-rc.d corosync enable
sudo sed -i 's/=no/=yes/' /etc/default/corosync
sudo scp /vagrant/corosync.conf /etc/corosync/corosync.conf
export ais_port=5405
export ais_mcast=239.255.42.1
export ais_addr=`ip addr | grep "inet " | tail -n 1 | awk '{print $4}' | sed s/255/0/`
exit
EOF

if [ ! -f /etc/corosync/authkey ]; then echo "No Corosync key. Installing it..."; else echo "There."; sudo rm /etc/corosync/authkey; fi

until [ -f /etc/corosync/authkey ]; do dd if=/dev/urandom of=/tmp/100 bs=1024 count=100000; for i in {1..10}; do cp /tmp/100 /tmp/tmp_$i_$RANDOM; done; rm -f /tmp/tmp_* /tmp/100; done & sudo /usr/sbin/corosync-keygen
#sudo rm /vagrant/authkey
sudo touch /vagrant/authkey
sudo chmod 0777 /vagrant/authkey
sudo scp /etc/corosync/authkey /vagrant/authkey
sshpass -p "vagrant" ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t -t vagrant@grizzly1 <<EOF
echo "SSH into grizzly1"
sudo touch /etc/corosync/authkey
sudo chmod 0777 /etc/corosync/authkey
sudo scp /vagrant/authkey /etc/corosync/authkey
sudo touch /etc/corosync/service.d/pcmk
sudo chmod 0777 /etc/corosync/service.d/pcmk
sudo scp /vagrant/pcmk /etc/corosync/service.d/pcmk
exit
EOF

sudo touch /etc/corosync/service.d/pcmk
sudo chmod 0777 /etc/corosync/service.d/pcmk
sudo scp /vagrant/pcmk /etc/corosync/service.d/pcmkk

sudo service corosync start
sudo corosync-cfgtool -s
sudo corosync-objctl runtime.totem.pg.mrp.srp.members

sshpass -p "vagrant" ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t -t vagrant@grizzly1 <<EOF
echo "SSH into grizzly1"
sudo service corosync start
sudo service pacemaker start
exit
EOF

sudo service pacemaker start

sudo crm configure property no-quorum-policy="ignore"
sudo crm configure property pe-warn-series-max="1000"
sudo crm configure property pe-input-series-max="1000"
sudo crm configure property pe-error-series-max="1000"
sudo crm configure property cluster-recheck-interval="5min"
sudo crm configure property stonith-enabled="false"
sudo crm configure property default-resource-stickiness="100"


fi
