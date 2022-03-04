
M = 1
W = 2
IP_NW = "192.168.57."

Vagrant.configure("2") do |config|

#config.ssh.insert_key = false

config.vm.box = "ubuntu/bionic64"
config.vm.box_check_update = false

#Disabling the default /vagrant share
# => config.vm.synced_folder ".", "/vagrant", disabled: true

config.vm.provision "shell", path: "bootstrap.sh"

# Control Plane master nodes
(1..M).each do |i|
  config.vm.define "kmaster#{i}" do |master|
    master.vm.hostname = "kmaster#{i}"
    master.vm.network :private_network, ip: IP_NW + "#{1+i}"
    master.vm.provider :virtualbox do |v|
      v.name    = "kmaster#{i}"
      v.memory  = 2048
      v.cpus    =  2
    end
   master.vm.provision "shell", path: "bootstrap_master.sh"

  end
end

# Workers nodes
(1..W).each do |i|
  config.vm.define "knode#{i}" do |node|
    node.vm.hostname = "knode#{i}"
    node.vm.network :private_network, ip: IP_NW + "#{10+i}"
    node.vm.provider :virtualbox do |v|
      v.name    = "knode#{i}"
      v.memory  = 2048
      v.cpus    =  2
    end
    node.vm.provision "shell", path: "bootstrap_nodes.sh"
  end
end

end
