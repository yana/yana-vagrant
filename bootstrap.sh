#!/usr/bin/env bash

set -e 
set -u


# Software install
# ----------------
#
# Utilities
#
if ! rpm -q epel-release
then
    rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm 
fi
yum -y install xmlstarlet unzip

#
# JRE
#
yum -y install java-1.6.0
#
# Tomcat
#
yum install -y tomcat6 tomcat6-webapps tomcat6-admin-webapps
chkconfig tomcat6 on

# Enable SSL

# Generate the keystore
keystore_file=/etc/tomcat6/yana/keystore
keystore_pass=password
if [ ! -f "$keystore_file" ]
then
    mkdir -p /etc/tomcat6/yana
    keytool -genkey -noprompt \
        -alias      tomcat \
        -keyalg     RSA \
        -dname "CN=yana.org, OU=CA, O=YANA, L=Yana, S=Yana, C=US" \
        -keystore "$keystore_file" \
        -storepass $keystore_pass \
        -keypass $keystore_pass
fi

# Deploy the Yana war
mkdir -p /var/lib/tomcat6/webapps/yana2
cp /vagrant/yana2-0.1.war /var/lib/tomcat6/webapps/yana2
cd /var/lib/tomcat6/webapps/yana2
unzip yana2-0.1.war
rm  yana2-0.1.war

http_port=8080
https_port=8443

if [ -f /etc/tomcat6/server.xml ]
then
    cp /etc/tomcat6/server.xml /etc/tomcat6/server.xml.$(date +"%Y-%m-%d-%S")
fi
sed -e "s,@http_port@,$http_port,g" \
    -e "s,@https_port@,$https_port,g" \
    -e "s,@keystore_file@,$keystore_file,g" \
    -e "s,@keystore_pass@,$keystore_pass,g" \
    /vagrant/server.xml > /etc/tomcat6/server.xml


server_url="https://localhost:$https_port/yana"
index_dir=/var/lib/yana/search
yana_db_dir=/var/lib/yana/db
mkdir -p $index_dir $yana_db_dir
chown -R tomcat:tomcat /var/lib/yana

if [ ! -f /etc/tomcat6/yana/config.groovy ]
then
    sed -e "s,@server_url@,$server_url,g" \
        -e "s,@http_port@,$http_port,g" \
        -e "s,@https_port@,$https_port,g" \
        -e "s,@index_dir@,$index_dir,g" \
        -e "s,@yana_db_dir@,$yana_db_dir,g" \
        /vagrant/config.groovy > /etc/tomcat6/yana/config.groovy
fi

if ! grep -q yana2.config.location /etc/tomcat6/tomcat6.conf 
then
    echo 'CATALINA_OPTS="-Dyana2.config.location=/etc/tomcat/yana/config.groovy -XX:MaxPermSize=256m -Xmx1024m -Xms256m"' >>  /etc/tomcat6/tomcat6.conf 
fi

#
# Disable the firewall so we can easily access it from the host
service iptables stop
#

if ! service tomcat6 status
then
    service tomcat6 start
fi


# Start up yana
# ----------------


echo "Yana started."

exit $?
