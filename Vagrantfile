
Vagrant.configure("2") do |config|

  config.vm.box = "CentOS-6.3-x86_64-minimal"

  config.vm.network :forwarded_port, guest: 8080, host: 18080

  config.vm.provision :shell, :path => "bootstrap.sh"

end
