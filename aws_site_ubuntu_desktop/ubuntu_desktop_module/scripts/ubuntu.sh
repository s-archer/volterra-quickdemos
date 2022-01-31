#!/bin/bash
cat << EOF > /etc/dhcp/dhclient.conf
timeout 300;
supersede domain-name-servers ${volt_ip}
EOF
dhclient
apt update
apt install nmap -y