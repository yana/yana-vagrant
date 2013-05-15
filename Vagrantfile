
Vagrant.configure("2") do |config|

  config.vm.box = "CentOS-6.3-x86_64-minimal"
  config.vm.hostname = "yana"
  config.vm.network :private_network, ip: "192.168.50.10"
  config.vm.network :forwarded_port, guest: 8080, host: 18080
  config.vm.provision :shell, :path => "bootstrap.sh", :args => "0.1 yana 192.168.50.10"
  config.vm.provision :shell, :path => "add-project.sh", :args => "examples http://192.168.50.10:8080/yana2"

end
