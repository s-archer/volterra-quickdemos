#!/bin/bash

# CHECK TO SEE NETWORK IS READY
CNT=0
while true
do
  STATUS=$(curl -s -k -I example.com | grep HTTP)
  if [[ $STATUS == *"200"* ]]; then
    echo "Got 200! NGINX is Ready!"
    break
  elif [ $CNT -le 360 ]; then
    echo "Status code: $STATUS  Not done yet..."
    CNT=$[$CNT+1]
  else
    echo "GIVE UP..."
    break
  fi
  sleep 10
done

#Get IP
local_ipv4="$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"


#Install Dockers
sudo snap install docker
sleep 10
# sudo curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
# sudo chmod +x /usr/local/bin/docker-compose

# #Run  nginx
# sleep 10
# cat << EOF > docker-compose.yml
# version: "3.7"
# services:
#   web:
#     image: nginxdemos/hello
#     ports:
#     - "80:80"
#     restart: always
#     command: [nginx-debug, '-g', 'daemon off;']
#     network_mode: "host"
# EOF
# sudo docker-compose up -d

echo "--- DOCKER PULL JUICE SHOP ---"
#docker pull bkimminich/juice-shop
docker pull arch8472/arch-juice:js-in-index
echo "--- DOCKER RUN JUICE SHOP ---"
#docker run -d -p 80:3000 bkimminich/juice-shop
docker run -d -p 80:3000 arch8472/arch-juice:js-in-index