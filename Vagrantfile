# -*- mode: ruby -*-
# vi: set ft=ruby :

# Copyright 2013 Zürcher Hochschule für Angewandte Wissenschaften
# All Rights Reserved.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

Vagrant::Config.run do |config|

  config.vm.define :grizzly1 do |grizzly1_config|

    grizzly1_config.vm.box = "precise64_with_services"
    grizzly1_config.vm.box_url = "https://www.dropbox.com/s/dln3v7nf8nwhf72/package.box"
    #grizzly1_config.vm.box_url = "http://files.vagrantup.com/precise64.box"

    # grizzly1_config.vm.boot_mode = :gui
    grizzly1_config.vm.network :hostonly, "10.1.2.44"
    #grizzly1_config.vm.network :bridged, "192.168.22.11"
    grizzly1_config.vm.network :hostonly, "192.168.22.11"
    #grizzly1_config.vm.network :bridged, "192.168.22.11"
    grizzly1_config.vm.host_name = "grizzly1"
    grizzly1_config.vm.customize ["modifyvm", :id, "--memory", 1024]
    grizzly1_config.ssh.max_tries = 100
    grizzly1_config.vm.forward_port 80, 8088
    grizzly1_config.vm.forward_port 22, 2223

    #grizzly1_config.persistent_storage.location = "~/development/sourcehdd1.vdi"
    #grizzly1_config.persistent_storage.size = 50000

    grizzly1_config.vm.provision :shell, :path => "prep.sh"
    grizzly1_config.vm.provision :puppet do |grizzly1_puppet|
      grizzly1_puppet.pp_path = "/tmp/vagrant-puppet"
      grizzly1_puppet.module_path = "modules"
      grizzly1_puppet.manifests_path = "manifests"
      grizzly1_puppet.manifest_file = "site1.pp"
      grizzly1_puppet.facter = { "fqdn" => "grizzly1" }
    end

    #grizzly1_config.vm.provision :shell, :path => "script.sh"
    grizzly1_config.vm.provision :shell, :path => "lvm-setup.sh"
    grizzly1_config.vm.provision :shell, :path => "sshtunnel.sh"
  end

  config.vm.define :grizzly2 do |grizzly2_config|

    grizzly2_config.vm.box = "precise64_with_services"
    grizzly2_config.vm.box_url = "https://www.dropbox.com/s/dln3v7nf8nwhf72/package.box"
    #grizzly2_config.vm.box_url = "http://files.vagrantup.com/precise64.box"

    # grizzly1_config.vm.boot_mode = :gui
    grizzly2_config.vm.network :hostonly, "10.1.2.45"
    #grizzly1_config.vm.network :bridged, "192.168.22.11"
    grizzly2_config.vm.network :hostonly, "192.168.22.12"
    #grizzly1_config.vm.network :bridged, "192.168.22.11"
    grizzly2_config.vm.host_name = "grizzly2"
    grizzly2_config.vm.customize ["modifyvm", :id, "--memory", 1024]
    grizzly2_config.ssh.max_tries = 100
    grizzly2_config.vm.forward_port 80, 8089
    grizzly2_config.vm.forward_port 22, 2224

    #grizzly2_config.persistent_storage.location = "~/development/sourcehdd2.vdi"
    #grizzly2_config.persistent_storage.size = 50000

    grizzly2_config.vm.provision :shell, :path => "prep.sh"
    grizzly2_config.vm.provision :puppet do |grizzly2_puppet|
      grizzly2_puppet.pp_path = "/tmp/vagrant-puppet"
      grizzly2_puppet.module_path = "modules"
      grizzly2_puppet.manifests_path = "manifests"
      grizzly2_puppet.manifest_file = "site2.pp"
      grizzly2_puppet.facter = { "fqdn" => "grizzly2" }
    end
    #grizzly2_config.vm.provision :shell, :path => "script.sh"
    grizzly2_config.vm.provision :shell, :path => "lvm-setup.sh"
    grizzly2_config.vm.provision :shell, :path => "sshtunnel.sh"
    
    grizzly2_config.vm.provision :shell, :path => "corosync-setup.sh"
    grizzly2_config.vm.provision :shell, :path => "drbd-setup.sh"
    grizzly2_config.vm.provision :shell, :path => "mysql_prep.sh"
    grizzly2_config.vm.provision :shell, :path => "pacemaker-prepare.sh"
  end
end
