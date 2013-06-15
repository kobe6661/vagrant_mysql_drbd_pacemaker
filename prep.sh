#!/bin/bash
sudo echo deb http://ubuntu-cloud.archive.canonical.com/ubuntu precise-updates/grizzly main >> /etc/apt/sources.list.d/grizzly.list
sudo apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 5EDB1B62EC4926EA

sudo apt-get update
sudo apt-get install libconfig-general-perl libibverbs1 librdmacm1 libsgutils2-2 sg3-utils tgt -y
#sudo apt-get upgrade -y
#sudo apt-get dist-upgrade -y
sudo apt-get update
DEBIAN_FRONTEND=noninteractive sudo apt-get -o Dpkg::Options::="--force-confnew" --force-yes -fuy upgrade

DEBIAN_FRONTEND=noninteractive sudo apt-get -o Dpkg::Options::="--force-confnew" --force-yes -fuy dist-upgrade

sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf

# Allow IPv4-forwarding
sysctl net.ipv4.ip_forward=1
