This is a single machine vagrant configuration that
provisions a YANA deployment.

## Vagrant configuration.

This vagrant configuration defines the following virtual machines:

* **yana**: A tomcat6 instance with the YANA application deployed.

The yana machine uses minimal centos base box and installs software via yum/rpm.

See the Vagrantfile for further details about changing parameters used
by the provisioning scripts.

## Requirements

* Internet access to download packages from public repositories.
* [Vagrant 1.2.2](http://downloads.vagrantup.com)

The vagrant provisioning scripts automatically 
download the YANA application from
bintray.com: https://bintray.com/pkg/show/general/ahonor/yana-war/yana

## Startup

Start up the VM like so:

    vagrant up 

The virtual machine brings up tomcat on a private IP address you can
access from your browser.

    http://192.168.50.10:8080/yana2
    
Login using user/pass: admin/admin


## Logins

You can login to the box like so:

    vagrant ssh

Once logged into the box you can become other users via
sudo/su.

### Log files

The tomcat log files are kept in /var/log/tomcat:

* catalina.out
* yana.log
