#!/bin/bash
# cat << EOF > /etc/dhcp/dhclient.conf
# timeout 300;
# supersede domain-name-servers ${volt_ip}
# EOF
# dhclient

#############################
# CONFIGURE LOGGING
#############################

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

#############################
# FIX AUTO_UPDATE FRONT-LOCK PROBLEM
#############################

sed -i 's/Update-Package-Lists "1"/Update-Package-Lists "0"/' /etc/apt/apt.conf.d/20auto-upgrades

#############################
# CHECK TO SEE NETWORK IS READY
#############################
count=0
while true
do
  STATUS=$(curl -s -k -I https://github.com | grep HTTP)
  if [[ $STATUS == *"200"* ]]; then
    echo "internet access check passed"
    break
  elif [ $count -le 120 ]; then
    echo "Status code: $STATUS  Not done yet..."
    count=$[$count+1]
  else
    echo "GIVE UP..."
    break
  fi
  sleep 10
done
apt update
apt install nmap -y