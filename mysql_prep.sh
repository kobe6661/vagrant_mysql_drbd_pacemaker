node=$(hostname)
node=$(echo $node)
echo "$node is active."


if [[ $node = "grizzly2" ]]; then

#sudo sed -i -e 's/\/var\/lib\/mysql/\/db\/mysql\/mysql/g' /db/mysql/my.cnf

sudo service mysql stop

sshpass -p "vagrant" ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t -t vagrant@grizzly1 <<EOF
echo "SSH into grizzly1"
sudo service mysql stop

sudo mkdir -p -m 0700 /db/mysql
sudo mount -t xfs -o noatime,nodiratime,attr2 /dev/VG_PG/LV_DATA /db/mysql
sudo chown -hR mysql:mysql /db/mysql/
sudo cp /etc/mysql/my.cnf /etc/mysql/myold.cnf
sudo sed -i -e 's/\/var\/lib\/mysql/\/db\/mysql\/mysql/g' /etc/mysql/my.cnf

sudo cp -aR /var/lib/mysql /db/mysql/

sudo mv /etc/mysql/my.cnf /db/mysql/mysql

sudo ln -s /db/mysql/mysql/my.cnf /etc/mysql/my.cnf



sudo sed -i -e 's/\/system\/cpu\/ r,/\/system\/cpu\/ r,\n  \/db\/mysql\/mysql\/ r,\n  \/db\/mysql\/mysql\/** rwk,/g' /etc/apparmor.d/usr.sbin.mysqld

sudo service apparmor restart

exit
EOF

sudo sed -i -e 's/\/system\/cpu\/ r,/\/system\/cpu\/ r,\n  \/db\/mysql\/mysql\/ r,\n  \/db\/mysql\/mysql\/** rwk,/g' /etc/apparmor.d/usr.sbin.mysqld

sudo service apparmor restart

sshpass -p "vagrant" ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t -t vagrant@grizzly1 <<EOF
echo "SSH into grizzly1"

sudo mysql_install_db --datadir=/db/mysql/mysql --user=mysql

sudo service mysql start

mysql -u root <<TEST
CREATE DATABASE IF NOT EXISTS drbdtest;
USE drbdtest;
CREATE TABLE users (id INTEGER(9), name VARCHAR(255)); 
TEST

sudo service mysql stop

sudo umount /db/mysql

sudo vgchange -an VG_PG  

sudo drbdadm --force secondary mysql

exit
EOF

sudo drbdadm --force primary mysql
sudo vgchange -ay VG_PG 

sudo mkdir -p -m 0700 /db/mysql
sudo mount -t xfs -o noatime,nodiratime,attr2 /dev/VG_PG/LV_DATA /db/mysql
sudo chown -hR mysql:mysql /db/mysql/
sudo cp /etc/mysql/my.cnf /etc/mysql/myold.cnf
sudo sed -i -e 's/\/var\/lib\/mysql/\/db\/mysql\/mysql/g' /etc/mysql/my.cnf

sudo cp -aR /var/lib/mysql /db/mysql/

sudo mv /etc/mysql/my.cnf /db/mysql/mysql

sudo ln -s /db/mysql/mysql/my.cnf /etc/mysql/my.cnf

sudo service mysql start

sudo service mysql stop

sudo update-rc.d mysql defaults

sshpass -p "vagrant" ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t -t vagrant@grizzly1 <<EOF
echo "SSH into grizzly1"
sudo update-rc.d mysql defaults
sudo update-rc.d mysql disable
exit
EOF

sudo update-rc.d mysql disable

### BEGIN INIT INFO \n# Provides:          mysql\n# Required-Start:    $remote_fs $syslog mysql-ndb\n# Required-Stop:     $remote_fs $syslog mysql-ndb\n# Should-Start:      $network $named $time\n# Should-Stop:       $network $named $time\n# Default-Start:     2 3 4 5\n# Default-Stop:      0 1 6\n# Short-Description: Start and stop the mysql database server daemon\n# Description:       Controls the main MySQL database server daemon "mysqld"\n#                    and its wrapper script "mysqld_safe".\n### END INIT INFO\n 

fi
