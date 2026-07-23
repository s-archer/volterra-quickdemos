#!/bin/bash
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

HOSTNAME_VALUE="${hostname}"
SERVER_NUMBER="${server_number}"
AWS_REGION="${aws_region}"
MGMT_MAC="$(echo "${mgmt_mac}" | tr '[:upper:]' '[:lower:]')"
INTERNAL_MAC="$(echo "${internal_mac}" | tr '[:upper:]' '[:lower:]')"
MGMT_GATEWAY="${mgmt_gateway}"
INTERNAL_GATEWAY="${internal_gateway}"
INTERNAL_VPC_CIDR="${internal_vpc_cidr}"
INTERNAL_PRIVATE_IP="${internal_private_ip}"
ENABLE_TAILSCALE_SUBNET_ROUTER="${enable_tailscale_subnet_router}"
TAILSCALE_AUTH_KEY="${tailscale_auth_key}"
TAILSCALE_TAG="${tailscale_tag}"
TAILSCALE_ADVERTISE_ROUTES="${tailscale_advertise_routes}"
INTERNAL_EXTRA_ROUTES="${internal_extra_routes}"
ENABLE_F5XC_CE_IPSEC="${enable_f5xc_ce_ipsec}"
F5XC_CE_IPSEC_PEER_IP="${f5xc_ce_ipsec_peer_ip}"
F5XC_CE_IPSEC_PSK="${f5xc_ce_ipsec_psk}"
F5XC_CE_IPSEC_REMOTE_ROUTES="${f5xc_ce_ipsec_remote_routes}"
F5XC_CE_IPSEC_INTERFACE_NAME="${f5xc_ce_ipsec_interface_name}"
F5XC_CE_IPSEC_INTERFACE_ID="${f5xc_ce_ipsec_interface_id}"
F5XC_CE_IPSEC_LOCAL_TUNNEL_IP="${f5xc_ce_ipsec_local_tunnel_ip}"
F5XC_CE_IPSEC_REMOTE_TUNNEL_IP="${f5xc_ce_ipsec_remote_tunnel_ip}"
F5XC_CE_IPSEC_IKE_PROPOSALS="${f5xc_ce_ipsec_ike_proposals}"
F5XC_CE_IPSEC_ESP_PROPOSALS="${f5xc_ce_ipsec_esp_proposals}"

hostnamectl set-hostname "$HOSTNAME_VALUE"

iface_for_mac() {
  local mac="$1"
  local iface

  for iface_path in /sys/class/net/*; do
    iface="$(basename "$iface_path")"
    if [ "$iface" = "lo" ]; then
      continue
    fi

    if [ "$(cat "$iface_path/address")" = "$mac" ]; then
      echo "$iface"
      return 0
    fi
  done

  return 1
}

for attempt in $(seq 1 60); do
  MGMT_IF="$(iface_for_mac "$MGMT_MAC" || true)"
  INTERNAL_IF="$(iface_for_mac "$INTERNAL_MAC" || true)"

  if [ -n "$MGMT_IF" ] && [ -n "$INTERNAL_IF" ]; then
    break
  fi

  sleep 2
done

if [ -z "$MGMT_IF" ] || [ -z "$INTERNAL_IF" ]; then
  echo "Could not map mgmt/internal interfaces from ENI MAC addresses" >&2
  exit 1
fi

cat >/usr/local/sbin/configure-linux-routing.sh <<'EOF'
#!/bin/bash
set -euxo pipefail

MGMT_IF="__MGMT_IF__"
INTERNAL_IF="__INTERNAL_IF__"
MGMT_GATEWAY="__MGMT_GATEWAY__"
INTERNAL_GATEWAY="__INTERNAL_GATEWAY__"
INTERNAL_VPC_CIDR="__INTERNAL_VPC_CIDR__"
INTERNAL_PRIVATE_IP="__INTERNAL_PRIVATE_IP__"
INTERNAL_EXTRA_ROUTES="__INTERNAL_EXTRA_ROUTES__"

ip route del default dev "$INTERNAL_IF" || true
ip route replace default via "$MGMT_GATEWAY" dev "$MGMT_IF" metric 100
ip route replace "$INTERNAL_VPC_CIDR" via "$INTERNAL_GATEWAY" dev "$INTERNAL_IF" src "$INTERNAL_PRIVATE_IP" metric 50

for route in $INTERNAL_EXTRA_ROUTES; do
  ip route replace "$route" via "$INTERNAL_GATEWAY" dev "$INTERNAL_IF" src "$INTERNAL_PRIVATE_IP" metric 40
done
EOF

sed -i \
  -e "s|__MGMT_IF__|$MGMT_IF|g" \
  -e "s|__INTERNAL_IF__|$INTERNAL_IF|g" \
  -e "s|__MGMT_GATEWAY__|$MGMT_GATEWAY|g" \
  -e "s|__INTERNAL_GATEWAY__|$INTERNAL_GATEWAY|g" \
  -e "s|__INTERNAL_VPC_CIDR__|$INTERNAL_VPC_CIDR|g" \
  -e "s|__INTERNAL_PRIVATE_IP__|$INTERNAL_PRIVATE_IP|g" \
  -e "s|__INTERNAL_EXTRA_ROUTES__|$INTERNAL_EXTRA_ROUTES|g" \
  /usr/local/sbin/configure-linux-routing.sh

chmod 0755 /usr/local/sbin/configure-linux-routing.sh

cat >/etc/systemd/system/configure-linux-routing.service <<'EOF'
[Unit]
Description=Configure Linux multi-interface routing
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/configure-linux-routing.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

cat >/etc/sysctl.d/99-multinic-tailscale.conf <<'EOF'
net.ipv4.ip_forward = 1
net.ipv4.conf.all.rp_filter = 2
net.ipv4.conf.default.rp_filter = 2
EOF

cat >>/etc/sysctl.d/99-multinic-tailscale.conf <<EOF
net.ipv4.conf.$MGMT_IF.rp_filter = 2
net.ipv4.conf.$INTERNAL_IF.rp_filter = 2
EOF

sysctl --system
systemctl daemon-reload
systemctl enable --now configure-linux-routing.service

apt-get update
apt-get install -y \
  ca-certificates \
  curl \
  gnupg \
  nano \
  nginx \
  iputils-ping \
  traceroute \
  charon-systemd \
  strongswan \
  strongswan-swanctl

cat >/var/www/html/index.html <<EOF
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>AWS Region: $AWS_REGION</title>
  <style>
    body {
      margin: 0;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      font-family: Arial, Helvetica, sans-serif;
      color: #1f2933;
      background: #f4f7fb;
    }
    main {
      text-align: center;
      padding: 2rem;
    }
    h1 {
      margin: 0 0 1rem;
      font-size: 2.5rem;
    }
    p {
      margin: 0;
      font-size: 1.25rem;
    }
    strong {
      color: #0067b8;
    }
  </style>
</head>
<body>
  <main>
    <h1>NGINX on AWS</h1>
    <p>server <strong>$SERVER_NUMBER</strong></p>
    <p>Serving from AWS region <strong>$AWS_REGION</strong></p>
  </main>
</body>
</html>
EOF

cp /var/www/html/index.html /var/www/html/index.nginx-debian.html
systemctl enable --now nginx

if [ "$ENABLE_F5XC_CE_IPSEC" = "true" ]; then
  if [ -z "$F5XC_CE_IPSEC_PSK" ]; then
    echo "F5 XC CE IPsec is enabled but no PSK was provided" >&2
    exit 1
  fi

  cat >/usr/local/sbin/configure-f5xc-ipsec-interface.sh <<'EOF'
#!/bin/bash
set -euxo pipefail

INTERNAL_IF="__INTERNAL_IF__"
IPSEC_IF="__IPSEC_IF__"
IPSEC_IF_ID="__IPSEC_IF_ID__"
LOCAL_TUNNEL_IP="__LOCAL_TUNNEL_IP__"
REMOTE_TUNNEL_IP="__REMOTE_TUNNEL_IP__"
REMOTE_ROUTES="__REMOTE_ROUTES__"

modprobe xfrm_interface || true

if ! ip link show "$IPSEC_IF" >/dev/null 2>&1; then
  ip link add "$IPSEC_IF" type xfrm dev "$INTERNAL_IF" if_id "$IPSEC_IF_ID"
fi

ip link set "$IPSEC_IF" up
ip addr replace "$LOCAL_TUNNEL_IP" dev "$IPSEC_IF"

for route in $REMOTE_ROUTES; do
  ip route replace "$route" dev "$IPSEC_IF" src "$${LOCAL_TUNNEL_IP%/*}" metric 30
done

ip route replace "$REMOTE_TUNNEL_IP/32" dev "$IPSEC_IF" src "$${LOCAL_TUNNEL_IP%/*}" metric 30
EOF

  sed -i \
    -e "s|__INTERNAL_IF__|$INTERNAL_IF|g" \
    -e "s|__IPSEC_IF__|$F5XC_CE_IPSEC_INTERFACE_NAME|g" \
    -e "s|__IPSEC_IF_ID__|$F5XC_CE_IPSEC_INTERFACE_ID|g" \
    -e "s|__LOCAL_TUNNEL_IP__|$F5XC_CE_IPSEC_LOCAL_TUNNEL_IP|g" \
    -e "s|__REMOTE_TUNNEL_IP__|$F5XC_CE_IPSEC_REMOTE_TUNNEL_IP|g" \
    -e "s|__REMOTE_ROUTES__|$${F5XC_CE_IPSEC_REMOTE_ROUTES//,/ }|g" \
    /usr/local/sbin/configure-f5xc-ipsec-interface.sh

  chmod 0755 /usr/local/sbin/configure-f5xc-ipsec-interface.sh

  cat >/etc/systemd/system/configure-f5xc-ipsec-interface.service <<'EOF'
[Unit]
Description=Configure route-based IPsec XFRM interface for F5 XC CE
After=configure-linux-routing.service
Requires=configure-linux-routing.service

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/configure-f5xc-ipsec-interface.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

  cat >/etc/swanctl/conf.d/f5xc-ce.conf <<EOF
connections {
  f5xc-ce {
    version = 2
    local_addrs = $INTERNAL_PRIVATE_IP
    remote_addrs = $F5XC_CE_IPSEC_PEER_IP
    proposals = $F5XC_CE_IPSEC_IKE_PROPOSALS
    if_id_in = $F5XC_CE_IPSEC_INTERFACE_ID
    if_id_out = $F5XC_CE_IPSEC_INTERFACE_ID
    mobike = no
    dpd_delay = 30s
    local {
      auth = psk
      id = $INTERNAL_PRIVATE_IP
    }
    remote {
      auth = psk
      id = $F5XC_CE_IPSEC_PEER_IP
    }
    children {
      vip-ranges {
        local_ts = 0.0.0.0/0
        remote_ts = 0.0.0.0/0
        if_id_in = $F5XC_CE_IPSEC_INTERFACE_ID
        if_id_out = $F5XC_CE_IPSEC_INTERFACE_ID
        esp_proposals = $F5XC_CE_IPSEC_ESP_PROPOSALS
        start_action = start
        dpd_action = restart
      }
    }
  }
}

secrets {
  ike-f5xc-ce {
    id-1 = $INTERNAL_PRIVATE_IP
    id-2 = $F5XC_CE_IPSEC_PEER_IP
    secret = "$F5XC_CE_IPSEC_PSK"
  }
}
EOF

  chmod 0600 /etc/swanctl/conf.d/f5xc-ce.conf
  systemctl daemon-reload
  systemctl enable --now configure-f5xc-ipsec-interface.service
  systemctl enable --now strongswan || systemctl enable --now strongswan-starter
  systemctl restart strongswan || systemctl restart strongswan-starter
  swanctl --load-all
  swanctl --initiate --child vip-ranges || true
fi

curl -fsSL https://tailscale.com/install.sh | sh
systemctl enable --now tailscaled

cat >/etc/systemd/system/tailscale-logout-on-shutdown.service <<'EOF'
[Unit]
Description=Logout Tailscale on shutdown
After=network-online.target tailscaled.service
Wants=network-online.target
Requires=tailscaled.service

[Service]
Type=oneshot
ExecStart=/bin/true
ExecStop=/bin/sh -c '/usr/bin/tailscale logout --reason=terraform-destroy || true'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now tailscale-logout-on-shutdown.service

if [ -n "$TAILSCALE_AUTH_KEY" ]; then
  if [ "$ENABLE_TAILSCALE_SUBNET_ROUTER" = "true" ]; then
    tailscale up \
      --authkey="$TAILSCALE_AUTH_KEY" \
      --hostname="$HOSTNAME_VALUE" \
      --advertise-tags="tag:$TAILSCALE_TAG" \
      --advertise-routes="$TAILSCALE_ADVERTISE_ROUTES" \
      --advertise-exit-node=false \
      --accept-dns=false \
      --snat-subnet-routes=false \
      --netfilter-mode=off
  else
    tailscale up \
      --authkey="$TAILSCALE_AUTH_KEY" \
      --hostname="$HOSTNAME_VALUE" \
      --accept-routes=true \
      --accept-dns=true
  fi
fi
