
Vagrant.configure("2") do |config|

  YANA_VERS = "0.1"
  PROJECT= "examples"
  config.vm.box = "CentOS-6.3-x86_64-minimal"
  config.vm.box_url = "https://dl.dropbox.com/u/7225008/Vagrant/CentOS-6.3-x86_64-minimal.box"
  config.vm.hostname = "yana"
  config.vm.network :private_network, ip: "192.168.50.10"
  config.vm.provision :shell, :path => "bootstrap.sh", :args => "#{YANA_VERS} yana 192.168.50.10"
  config.vm.provision :shell, :path => "add-project.sh", :args => "#{PROJECT} http://192.168.50.10:8080/yana2"

end
