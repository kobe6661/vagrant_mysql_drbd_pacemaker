vagrant_mysql_drbd_pacemaker
=======================

This Vagrant script installs 2 VM nodes using Vagrant, Puppet and Virtualbox. Both nodes operate a MySQL server on a redundant DRBD device. The MySQL server is reached on a virtual IP which is shared between nodes. When a MySQL node fails, Pacemaker switches control flow to the other node and organizes failover tasks.

Prerequisites
=======================
Vagrant, Puppet, Virtualbox

Installation
=======================
1. Install Vagrant, Puppet and Virtualbox
2. Clone this repository to a folder (e. g. grizzly_test)
3. Open a terminal and cd to your folder.
4. Run "vagrant up" in the terminal.
5. Wait for about 5-10 min. (the script takes time ;-))
6. Done.

Now you can access the OpenStack-Dashboard with your web browser by tiping the URL "http://192.168.22.11/horizon".
Login with user name "admin" and password "admin_pass". Have fun!
