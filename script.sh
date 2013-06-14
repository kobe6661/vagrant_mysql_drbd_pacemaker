#!/bin/bash

#sudo su -
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confnew" --force-yes -fuy upgrade

DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confnew" --force-yes -fuy dist-upgrade

#apt-get dist-upgrade -y

# Allow remote MySQL-connections
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/my.cnf
sudo service mysql restart

sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf

# Allow IPv4-forwarding
sysctl net.ipv4.ip_forward=1

mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS keystone;
GRANT ALL ON keystone.* TO 'keystoneUser'@'%' IDENTIFIED BY 'keystonePass'; 
EOF

DBTRUE=echo $?

echo "Connection success: $DBTRUE"

sed -i -e 's/connection = sqlite:\/\/\/\/var\/lib\/keystone\/keystone.db/connection = mysql:\/\/keystoneUser:keystonePass@10.1.2.44\/keystone/g' /etc/keystone/keystone.conf

service keystone restart
keystone-manage db_sync

cp /vagrant/keystone_basic.sh keystone_basic.sh
cp /vagrant/keystone_endpoints_basic.sh keystone_endpoints_basic.sh

chmod +x keystone_basic.sh
chmod +x keystone_endpoints_basic.sh

./keystone_basic.sh
./keystone_endpoints_basic.sh

touch creds
chmod +x creds

echo "export OS_TENANT_NAME=admin" >> creds
echo "export OS_USERNAME=admin" >> creds
echo "export OS_PASSWORD=admin_pass" >> creds
echo 'export OS_AUTH_URL="http://192.168.22.11:5000/v2.0/"'>> creds

source creds

mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS glance;
GRANT ALL ON glance.* TO 'glanceUser'@'%' IDENTIFIED BY 'glancePass';
EOF

echo "auth_host = 10.1.2.44" >> /etc/glance/glance-api-paste.ini
echo "auth_port = 35357" >> /etc/glance/glance-api-paste.ini
echo "auth_protocol = http" >> /etc/glance/glance-api-paste.ini
echo "admin_tenant_name = service" >> /etc/glance/glance-api-paste.ini
echo "admin_user = glance" >> /etc/glance/glance-api-paste.ini
echo "admin_password = service_pass" >> /etc/glance/glance-api-paste.ini

echo "auth_host = 10.1.2.44" >> /etc/glance/glance-registry-paste.ini
echo "auth_port = 35357" >> /etc/glance/glance-registry-paste.ini
echo "auth_protocol = http" >> /etc/glance/glance-registry-paste.ini
echo "admin_tenant_name = service" >> /etc/glance/glance-registry-paste.ini
echo "admin_user = glance" >> /etc/glance/glance-registry-paste.ini
echo "admin_password = service_pass" >> /etc/glance/glance-registry-paste.ini

sed -i -e 's/sql_connection = sqlite:\/\/\/\/var\/lib\/glance\/glance.sqlite/sql_connection = mysql:\/\/glanceUser:glancePass@10.1.2.44\/glance/g' /etc/glance/glance-api.conf
echo "flavor = keystone" >> /etc/glance/glance-api.conf
sed -i -e 's/sql_connection = sqlite:\/\/\/\/var\/lib\/glance\/glance.sqlite/sql_connection = mysql:\/\/glanceUser:glancePass@10.1.2.44\/glance/g' /etc/glance/glance-registry.conf
echo "flavor = keystone" >> /etc/glance/glance-registry.conf
service glance-api restart; service glance-registry restart
glance-manage db_sync

glance image-create --name myFirstImage --is-public true --container-format bare --disk-format qcow2 --location https://launchpad.net/cirros/trunk/0.3.0/+download/cirros-0.3.0-x86_64-disk.img

mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS quantum;
GRANT ALL ON quantum.* TO 'quantumUser'@'%' IDENTIFIED BY 'quantumPass'; 
EOF

cd /etc/init.d/; for i in $( ls quantum-* ); do sudo service $i status; done

cd ~

sed -i -e 's/\[filter:authtoken\]//g' /etc/quantum/api-paste.ini
sed -i -e 's/paste.filter_factory = keystoneclient.middleware.auth_token:filter_factory//g' /etc/quantum/api-paste.ini

echo "[filter:authtoken]" >> /etc/quantum/api-paste.ini
echo "paste.filter_factory = keystoneclient.middleware.auth_token:filter_factory" >> /etc/quantum/api-paste.ini

echo "auth_host = 10.1.2.44" >> /etc/quantum/api-paste.ini
echo "auth_port = 35357" >> /etc/quantum/api-paste.ini
echo "auth_protocol = http" >> /etc/quantum/api-paste.ini
echo "admin_tenant_name = service" >> /etc/quantum/api-paste.ini
echo "admin_user = quantum" >> /etc/quantum/api-paste.ini
echo "admin_password = service_pass" >> /etc/quantum/api-paste.ini


sed -i -e 's/core_plugin = quantum.plugins.openvswitch.ovs_quantum_plugin.OVSQuantumPluginV2/core_plugin = quantum.plugins.linuxbridge.lb_quantum_plugin.LinuxBridgePluginV2/g' /etc/quantum/quantum.conf

sed -i -e 's/sql_connection = sqlite:\/\/\/\/var\/lib\/quantum\/linuxbridge.sqlite/sql_connection = mysql:\/\/quantumUser:quantumPass@10.1.2.44\/quantum/g'  /etc/quantum/plugins/linuxbridge/linuxbridge_conf.ini

#[LINUX_BRIDGE]
sed -i -e "s/\[LINUX_BRIDGE\]/\[LINUX_BRIDGE\]\nphysical_interface_mappings = physnet1:eth2/g" /etc/quantum/plugins/linuxbridge/linuxbridge_conf.ini

# under [VLANS] section
sed -i -e "s/\[VLANS\]/\[VLANS\]\ntenant_network_type = vlatenant_network_type = vlan\nnetwork_vlan_ranges = physnet1:1000:2999/g" /etc/quantum/plugins/linuxbridge/linuxbridge_conf.ini
#tenant_network_type = vlan
#network_vlan_ranges = physnet1:1000:2999

sed -i -e "s/interface_driver = quantum.agent.linux.interface.OVSInterfaceDriver/interface_driver = quantum.agent.linux.interface.BridgeInterfaceDriver/g" /etc/quantum/l3_agent.ini

sed -i -e "s/auth_host = 127.0.0.1/auth_host = 10.1.2.44/g" /etc/quantum/quantum.conf
sed -i -e "s/admin_tenant_name = %SERVICE_TENANT_NAME%/admin_tenant_name = service/g" /etc/quantum/quantum.conf
sed -i -e "s/admin_user = %SERVICE_USER%/admin_user = quantum/g" /etc/quantum/quantum.conf
sed -i -e "s/admin_password = %SERVICE_PASSWORD%/admin_password = service_pass/g" /etc/quantum/quantum.conf

sed -i -e "s/interface_driver = quantum.agent.linux.interface.OVSInterfaceDriver/interface_driver = quantum.agent.linux.interface.BridgeInterfaceDriver/g" /etc/quantum/dhcp_agent.ini

sed -i -e "s/auth_url = http:\/\/localhost:35357\/v2.0/auth_url = http:\/\/10.1.2.44:35357\/v2.0/g" /etc/quantum/metadata_agent.ini

sed -i -e "s/admin_tenant_name = %SERVICE_TENANT_NAME%/admin_tenant_name = service/g" /etc/quantum/metadata_agent.ini
sed -i -e "s/admin_user = %SERVICE_USER%/admin_user = quantum/g" /etc/quantum/metadata_agent.ini
sed -i -e "s/admin_password = %SERVICE_PASSWORD%/admin_password = service_pass/g" /etc/quantum/metadata_agent.ini

sed -i -e "s/\# nova_metadata_ip = 127.0.0.1/nova_metadata_ip = 10.1.2.44/g" /etc/quantum/metadata_agent.ini

sed -i -e "s/\# nova_metadata_port = 8775/nova_metadata_port = 8775/g" /etc/quantum/metadata_agent.ini
sed -i -e "s/\# metadata_proxy_shared_secret =/metadata_proxy_shared_secret = helloOpenStack/g" /etc/quantum/metadata_agent.ini

cd /etc/init.d/; for i in $( ls quantum-* ); do sudo service $i restart; done

PROCESS=$(netstat -nap | grep ^tcp | grep :53 | awk '{printf("%s\n", substr($7, 1, index($7, "/") - 1))}')
kill $PROCESS
service dnsmasq restart

sed -i -e "s/\#cgroup_device_acl = \[/cgroup_device_acl = \[/g" /etc/libvirt/qemu.conf
sed -i -e 's/\#    "\/dev\/null", "\/dev\/full", "\/dev\/zero",/    "\/dev\/null", "\/dev\/full", "\/dev\/zero",/g' /etc/libvirt/qemu.conf
sed -i -e 's/\#    "\/dev\/random", "\/dev\/urandom",/    "\/dev\/random", "\/dev\/urandom",/g' /etc/libvirt/qemu.conf
sed -i -e 's/\#    "\/dev\/ptmx", "\/dev\/kvm", "\/dev\/kqemu",/    "\/dev\/ptmx", "\/dev\/kvm", "\/dev\/kqemu",/g' /etc/libvirt/qemu.conf
sed -i -e 's/\#    "\/dev\/rtc","\/dev\/hpet"/    "\/dev\/rtc","\/dev\/hpet"/g' /etc/libvirt/qemu.conf
sed -i -e 's/\#\]/\]/g' /etc/libvirt/qemu.conf

virsh net-destroy default
virsh net-undefine default

sed -i -e 's/\#listen_tls = 0/listen_tls = 0/g' /etc/libvirt/libvirtd.conf
sed -i -e 's/\#listen_tcp = 1/listen_tcp = 1/g' /etc/libvirt/libvirtd.conf
sed -i -e 's/\#auth_tls = "none"/auth_tcp = "none"/g' /etc/libvirt/libvirtd.conf

sed -i -e 's/env libvirtd_opts="-d"/env libvirtd_opts="-d -l"/g' /etc/init/libvirt-bin.conf 

sed -i -e 's/libvirtd_opts="-d"/libvirtd_opts="-d -l"/g' /etc/default/libvirt-bin

service libvirt-bin restart

mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS nova;
GRANT ALL ON nova.* TO 'novaUser'@'%' IDENTIFIED BY 'novaPass'; 
EOF

sed -i -e "s/auth_host = 127.0.0.1/auth_host = 10.1.2.44/g" /etc/nova/api-paste.ini
sed -i -e "s/admin_tenant_name = %SERVICE_TENANT_NAME%/admin_tenant_name = service/g" /etc/nova/api-paste.ini
sed -i -e "s/admin_user = %SERVICE_USER%/admin_user = nova/g" /etc/nova/api-paste.ini
sed -i -e "s/admin_password = %SERVICE_PASSWORD%/admin_password = service_pass/g" /etc/nova/api-paste.ini

 cp /vagrant/nova.conf /etc/nova/nova.conf

sed -i -e "s/libvirt_type=kvm/libvirt_type=qemu/g" /etc/nova/nova-compute.conf
sed -i -e "s/compute_driver=libvirt.LibvirtDriver/compute_driver=libvirt.LibvirtDriver\nlibvirt_vif_type=ethernet\nlibvirt_vif_driver=nova.virt.libvirt.vif.QuantumLinuxBridgeVIFDriver/g" /etc/nova/nova-compute.conf

nova-manage db sync

cd /etc/init.d/; for i in $( ls nova-* ); do sudo service $i restart; done

sed -i 's/false/true/g' /etc/default/iscsitarget

#sudo m-a a-i iscsitarget

apt-get install -y linux-headers-$(uname -r)

service iscsitarget start
service open-iscsi start

mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS cinder;
GRANT ALL ON cinder.* TO 'cinderUser'@'%' IDENTIFIED BY 'cinderPass'; 
EOF

sed -i -e "s/service_host = 127.0.0.1/service_host = 192.168.22.11/g" /etc/cinder/api-paste.ini
sed -i -e "s/auth_host = 127.0.0.1/auth_host = 10.1.2.44/g" /etc/cinder/api-paste.ini
sed -i -e "s/admin_tenant_name = %SERVICE_TENANT_NAME%/admin_tenant_name = service/g" /etc/cinder/api-paste.ini
sed -i -e "s/admin_user = %SERVICE_USER%/admin_user = cinder/g" /etc/cinder/api-paste.ini
sed -i -e "s/admin_password = %SERVICE_PASSWORD%/admin_password = service_pass/g" /etc/cinder/api-paste.ini

sed -i -e "s/iscsi_helper = tgtadm/iscsi_helper = ietadm/g" /etc/cinder/cinder.conf
echo "sql_connection = mysql://cinderUser:cinderPass@10.1.2.44/cinder" >> /etc/cinder/cinder.conf

cinder-manage db sync

dd if=/dev/zero of=cinder-volumes bs=1 count=0 seek=2G
losetup /dev/loop2 cinder-volumes
fdisk /dev/loop2 <<EOF
n
p
1


t
8e
w
EOF

partprobe /dev/loop2
pvcreate /dev/loop2
vgcreate cinder-volumes /dev/loop2

cd /etc/init.d/; for i in $( ls cinder-* ); do sudo service $i restart; done

sudo service apache2 restart
sudo service memcached restart
echo "Done."


sudo sed -i 's/=no/=yes/' /etc/default/corosync
sudo cp /vagrant/corosync.conf /etc/corosync/corosync.conf

#exit 0
#sed -i -e 's/exit 0/losetup \/dev\/loop2 \/var\/lib\/cinder\/volumes \nexit 0/g' /etc/rc.local
#exit 0

#exit 0

