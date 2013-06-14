#Update /etc/hosts (list of known hosts)
echo '192.168.22.11    grizzly1 grizzly1 precise64' >> /etc/hosts
echo '192.168.22.12    grizzly2 grizzly2 precise64' >> /etc/hosts
echo '10.1.2.44       grizzly1 grizzly1 precise64' >> /etc/hosts
echo '10.1.2.45       grizzly2 grizzly2 precise64' >> /etc/hosts

node=$(hostname)
node=$(echo $node)
echo "$node is active. Generating SSH Tunnel."


#Create SSH keys on both nodes
if [[ $node = "grizzly1" ]]; then
   if [ ! -d "/vagrant/.ssh" ]; then
       echo "Create SSH directory."
       sudo mkdir /vagrant/.ssh
   fi
   if [ ! -f "/vagrant/.ssh/id_rsa1" ]; then
       echo "Generate SSH key."
       sudo ssh-keygen -t rsa <<EOF
/vagrant/.ssh/id_rsa1


EOF
   fi
elif [[ $node = "grizzly2" ]]; then
   if [ ! -d "/vagrant/.ssh" ]; then
       echo "Create SSH directory."
       sudo mkdir /vagrant/.ssh
   fi
   if [ ! -f "/vagrant/.ssh/id_rsa2" ]; then
       echo "Create SSH directory."
       sudo ssh-keygen -t rsa <<EOF
/vagrant/.ssh/id_rsa2


EOF
   fi
else
   echo "Node not found."
fi


# Copy SSH keypairs to each node
if [[ $node = "grizzly1" ]]; then
   if [ ! -d "~root/.ssh" ]; then
       echo "Create root SSH directory to allow public keys."
       sudo mkdir ~root/.ssh
   fi
   if [ ! -f "~root/.ssh/authorized_keys" ]; then
       echo "Copy public keys into SSH directory."
       sudo cat /vagrant/.ssh/id_rsa1.pub >> ~root/.ssh/authorized_keys
       sudo cat /vagrant/.ssh/id_rsa2.pub >> ~root/.ssh/authorized_keys
   fi
   # Add grizzly2 to list of known hosts
   echo "Adding nodes to list of known hosts."
   sudo ssh-keyscan -t rsa 10.1.2.44 >> ~/.ssh/known_hosts
   sudo ssh-keyscan -t rsa 10.1.2.45 >> ~/.ssh/known_hosts
   # Disable strict host key checking
   echo "Disabling strict host key checking."
   echo "Host grizzly2" >> /etc/ssh/ssh_config
   echo "   Hostname 10.1.2.45" >> /etc/ssh/ssh_config
   echo "   StrictHostKeyChecking no" >> /etc/ssh/ssh_config
   echo "   UserKnownHostsFile=/dev/null" >> /etc/ssh/ssh_config
elif [[ $node = "grizzly2" ]]; then
   # Boot into grizzly2 and authorize public keys
   if [ ! -d "~root/.ssh" ]; then
       echo "Create root SSH directory to allow public keys."
       sudo mkdir ~root/.ssh
   fi
   if [ ! -f "~root/.ssh/authorized_keys" ]; then
       sudo cat /vagrant/.ssh/id_rsa1.pub >> ~root/.ssh/authorized_keys
       sudo cat /vagrant/.ssh/id_rsa2.pub >> ~root/.ssh/authorized_keys
   fi
   # Disable strict host key checking
   echo "Host grizzly1" >> /etc/ssh/ssh_config
   echo "   Hostname 10.1.2.44" >> /etc/ssh/ssh_config
   echo "   StrictHostKeyChecking no" >> /etc/ssh/ssh_config
   echo "   UserKnownHostsFile=/dev/null" >> /etc/ssh/ssh_config
   # Add grizzly1 to list of known hosts
   sudo ssh-keyscan -t rsa 10.1.2.44 >> ~/.ssh/known_hosts
   sudo ssh-keyscan -t rsa 10.1.2.45 >> ~/.ssh/known_hosts
   # SSH into grizzly1 and authorize public keys
   sshpass -p "vagrant" ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t -t vagrant@grizzly1 <<EOF
echo "SSH into grizzly1"
sudo su -
if [ ! -d "~root/.ssh" ];
then
  sudo mkdir ~root/.ssh
fi
if [ ! -f "~root/.ssh/authorized_keys" ]; then
 sudo cat /vagrant/.ssh/id_rsa1.pub >> ~root/.ssh/authorized_keys
 sudo cat /vagrant/.ssh/id_rsa2.pub >> ~root/.ssh/authorized_keys
fi
exit
exit
EOF
fi
