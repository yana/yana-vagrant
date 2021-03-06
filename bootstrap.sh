#!/usr/bin/env bash

# Exit immediately on error or undefined variable.
set -e 
set -u

# Process command line arguments.
if [ $# -ne 3 ]
then
    echo >&2 "usage: bootstrap verion name ip"
    exit 1
fi
YANA_VERSION=$1
HOST_NAME=$2
HOST_IP=$3


# Install software
# ----------------

#
# Utilities.
# Bootstrap a fedora repo to get xmlstarlet
if ! rpm -q epel-release
then
    rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm 
fi
yum -y install xmlstarlet unzip

#
# JRE.
#
yum -y install java-1.6.0
#
# Tomcat.
#
yum install -y tomcat6 tomcat6-webapps tomcat6-admin-webapps
chkconfig tomcat6 on

#
# Yana.
#
WAR=yana2-${YANA_VERSION}.war
WAR_URL=http://dl.bintray.com/ahonor/yana-war/$WAR

mkdir -p /var/lib/tomcat6/webapps/yana2
cd /var/lib/tomcat6/webapps/yana2
curl -f -s -L $WAR_URL -o ${WAR} -z ${WAR}
unzip -o ${WAR}

#
# Configure software.
# -------------------

# Begin configuration to enable SSL.

http_port=8080
https_port=8443

# Generate the keystore.
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
# Configure tomcat to use our ports and keystore.
# Copy existing configuration to a backup file.
if [ -f /etc/tomcat6/server.xml ]
then

    cp /etc/tomcat6/server.xml /etc/tomcat6/server.xml.$(date +"%Y-%m-%d-%S")
fi
sed -e "s,@http_port@,$http_port,g" \
    -e "s,@https_port@,$https_port,g" \
    -e "s,@keystore_file@,$keystore_file,g" \
    -e "s,@keystore_pass@,$keystore_pass,g" \
    /vagrant/server.xml > /etc/tomcat6/server.xml


# Configure the yana application base url, index and db dir.

server_url="https://$HOST_IP:$https_port/yana2"
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

# Add yana configuration location and java startup flags to Tomcat.
if ! grep -q yana2.config.location /etc/tomcat6/tomcat6.conf 
then
    cat >>  /etc/tomcat6/tomcat6.conf  <<EOF
CATALINA_OPTS="-Dyana2.config.location=/etc/tomcat6/yana/config.groovy -XX:MaxPermSize=256m -Xmx1024m -Xms256m"
EOF
fi

#
# Disable the firewall so we can easily access it from any host.
service iptables stop
#


# Start yana.
# -------------

set +e; # shouldn't have to turn off errexit.

# Check if tomcat is running and start it if necessary.
# Checks if startup message is contained by log file.
# Fails and exits non-zero if reaches max tries.
if ! service tomcat6 status
then

    success_msg="INFO: Server startup in"
    let count=0
    let max=18

    service tomcat6 start
    while [ $count -le $max ]
    do
        if ! grep "${success_msg}" /var/log/tomcat6/catalina.out
        then  printf >&2 ".";#  output message.
        else  break; # found successful startup message.
        fi
        let count=$count+1;# increment attempts
        [ $count -eq $max ] && {
            echo >&2 "FAIL: Reached max attempts to find success message in log. Exiting."
            exit 1
        }
        sleep 10; # wait 10s before trying again.
    done
fi


echo "Yana started."

# Done.
exit $?
