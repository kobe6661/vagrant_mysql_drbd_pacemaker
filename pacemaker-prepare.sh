node=$(hostname)
node=$(echo $node)
echo "$node is active."


if [[ $node = "grizzly2" ]]; then

#Configure DRBD resource "mysql.res"
sudo crm configure primitive p_drbd_mysql ocf:linbit:drbd params drbd_resource="mysql" drbdconf="/etc/drbd.conf" op start interval="0" timeout="90s" op stop interval="0" timeout="180s" op promote interval="0" timeout="180s" op demote interval="0" timeout="180s" op monitor interval="10s" role="Slave" timeout="20s" op monitor interval="11s" role="Master" timeout="21s"
 
#Configure Master
sudo crm configure ms ms_drbd_mysql p_drbd_mysql meta master-max="1" master-node-max="1" clone-max="2" clone-node-max="1" notify="true"

#Configure DRBD Volume Group
sudo crm configure primitive p_lvm_mysql ocf:heartbeat:LVM params volgrpname="VG_PG" op start interval="0" timeout="30" op stop interval="0" timeout="30"
#Configure DRBD Filesystem to work with LVM
sudo crm configure primitive p_fs_mysql ocf:heartbeat:Filesystem params device="/dev/VG_PG/LV_DATA" directory="/db/mysql" fstype="xfs" options="noatime,nodiratime" op start timeout="60s" op stop timeout="180s" op monitor interval="60s" timeout="60s"
#Configure LSB to work with MySQL
#sudo crm configure primitive p_lsb_mysql lsb:mysql op monitor interval="30" timeout="60" op start interval="0" timeout="60" op stop interval="0" timeout="60"
#Create Virtual IP for MySQL
sudo crm configure primitive p_ip_mysql ocf:heartbeat:IPaddr2 params ip="10.1.2.101" iflabel="mysqlvip" cidr_netmask="24" nic="eth1" op monitor interval="30s"
#Load MySQL configs
sudo crm configure primitive p_mysql ocf:heartbeat:mysql params additional_parameters="--bind-address=10.1.2.101" config="/db/mysql/mysql/my.cnf" pid="/var/run/mysqld/mysqld.pid" socket="/var/run/mysqld/mysqld.sock" log="/var/log/mysql/mysqld.log" op monitor interval="20s" timeout="10s" op start interval="0" timeout="120s" op stop interval="0" timeout="120s" meta target-role="Started"
#Create Service Group
sudo crm configure group g_mysql p_ip_mysql p_lvm_mysql p_fs_mysql p_mysql 
#Configure Colocation
sudo crm configure colocation c_mysql_on_drbd inf: g_mysql ms_drbd_mysql:Master
#Configure order
sudo crm configure order o_drbd_before_mysql inf: ms_drbd_mysql:promote g_mysql:start

fi
