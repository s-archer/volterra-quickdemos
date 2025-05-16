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

#Utils
sudo apt-get install unzip

#Download Consul
CONSUL_VERSION="1.7.2"
curl --silent --remote-name https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip

#Install Consul
unzip consul_${CONSUL_VERSION}_linux_amd64.zip
sudo chown root:root consul
sudo mv consul /usr/local/bin/
consul -autocomplete-install
complete -C /usr/local/bin/consul consul

#Create Consul User
sudo useradd --system --home /etc/consul.d --shell /bin/false consul
sudo mkdir --parents /opt/consul
sudo chown --recursive consul:consul /opt/consul

#Create Systemd Config
sudo cat << EOF > /etc/systemd/system/consul.service
[Unit]
Description="HashiCorp Consul - A service mesh solution"
Documentation=https://www.consul.io/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/consul.d/consul.hcl

[Service]
User=consul
Group=consul
ExecStart=/usr/local/bin/consul agent -config-dir=/etc/consul.d/
ExecReload=/usr/local/bin/consul reload
KillMode=process
Restart=always
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

#Create config dir
sudo mkdir --parents /etc/consul.d
sudo touch /etc/consul.d/consul.hcl
sudo chown --recursive consul:consul /etc/consul.d
sudo chmod 640 /etc/consul.d/consul.hcl

cat << EOF > /etc/consul.d/consul.hcl
datacenter = "dc1"
data_dir = "/opt/consul"
ui = true
EOF

cat << EOF > /etc/consul.d/client.hcl
advertise_addr = "${local_ipv4}"
retry_join = ["provider=aws tag_key=Env tag_value=consul"]
EOF

cat << EOF > /etc/consul.d/nginx.json
{
  "service": {
    "name": "nginx",
    "port": 80,
    "checks": [
      {
        "id": "nginx",
        "name": "nginx TCP Check",
        "tcp": "localhost:80",
        "interval": "10s",
        "timeout": "1s"
      }
    ]
  }
}
EOF

#Enable the service
sudo systemctl enable consul
sudo service consul start
sudo service consul status

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