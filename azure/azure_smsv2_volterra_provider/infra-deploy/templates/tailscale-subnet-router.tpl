#cloud-config
package_update: true
packages:
 - curl
 - frr
 - libcharon-extra-plugins
 - libstrongswan-extra-plugins
 - nginx
 - strongswan
 - strongswan-swanctl

bootcmd:
 - mkdir -p /etc/systemd/system/frr.service.d

write_files:
- path: /tmp/nginx-index.html
  owner: root:root
  permissions: '0644'
  content: |
    <!doctype html>
    <html lang="en">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <title>Tailscale Subnet Router: ${azure_region}</title>
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
        <h1>Tailscale Subnet Router</h1>
        <p>Serving from Azure region <strong>${azure_region}</strong></p>
      </main>
    </body>
    </html>
- path: /usr/local/sbin/configure-xfrm-ipsec.sh
  owner: root:root
  permissions: '0755'
  content: |
    #!/bin/bash
    set -euo pipefail
    exec > >(tee -a /var/log/configure-xfrm-ipsec.log) 2>&1
    set -x
    trap 'echo "configure-xfrm-ipsec failed at line $LINENO with exit code $?"' ERR

    LOCAL_PRIVATE_IP="${local_private_ip}"
    REMOTE_PRIVATE_IP="${remote_private_ip}"
    IPSEC_PSK="${strongswan_ipsec_psk}"

    modprobe xfrm_interface

    if ip link show ipsec0 >/dev/null 2>&1; then
      ip link delete ipsec0
    fi

    UNDERLAY_IF="$(ip route show default | awk '{print $5; exit}')"
    ip link add ipsec0 type xfrm dev "$UNDERLAY_IF" if_id 42
    ip link set ipsec0 up mtu 1370
    ip addr replace 172.16.1.2/24 dev ipsec0

    sysctl -w net.ipv4.ip_forward=1
    sysctl -w net.ipv4.conf.ipsec0.rp_filter=0
    sysctl -w net.ipv4.conf.ipsec0.disable_policy=0
    sysctl -w net.ipv4.conf.ipsec0.disable_xfrm=0

    install -d -o frr -g frr -m 0750 /etc/frr
    cat >/etc/frr/daemons <<EOF
    zebra=yes
    bgpd=yes
    ospfd=no
    ospf6d=no
    ripd=no
    ripngd=no
    isisd=no
    pimd=no
    ldpd=no
    nhrpd=no
    eigrpd=no
    babeld=no
    sharpd=no
    pbrd=no
    bfdd=no
    fabricd=no
    vrrpd=no
    pathd=no

    vtysh_enable=yes
    zebra_options="  -A 127.0.0.1 -s 90000000"
    bgpd_options="   -A 127.0.0.1"
    staticd_options="-A 127.0.0.1"
    watchfrr_options=""
    EOF

    cat >/etc/frr/frr.conf <<EOF
    frr defaults traditional
    hostname tailscale-subnet-router
    service integrated-vtysh-config
    !
    router bgp 64510
     bgp router-id 172.16.1.2
     no bgp ebgp-requires-policy
     neighbor 172.16.1.1 remote-as 64500
     neighbor 172.16.1.1 description F5_XC_CE_Tunnel_IP
     neighbor 172.16.1.1 ebgp-multihop 255
     neighbor 172.16.1.1 update-source ipsec0
     !
     address-family ipv4 unicast
      network 100.64.10.0/24
      neighbor 172.16.1.1 soft-reconfiguration inbound
     exit-address-family
    !
    EOF

    chown frr:frr /etc/frr/daemons /etc/frr/frr.conf
    chmod 0640 /etc/frr/daemons /etc/frr/frr.conf

    mkdir -p /etc/strongswan.d/charon
    cat >/etc/strongswan.d/charon/vici.conf <<EOF
    vici {
        load = yes
        socket = unix:///var/run/charon.vici
    }
    EOF

    mkdir -p /etc/swanctl/conf.d
    cat >/etc/swanctl/conf.d/f5xc-ce.conf <<EOF
    connections {
      f5xc-ce {
        version = 2

        local_addrs = $LOCAL_PRIVATE_IP
        remote_addrs = $REMOTE_PRIVATE_IP

        proposals = aes256-sha256-modp2048

        if_id_in = 42
        if_id_out = 42

        mobike = no
        dpd_delay = 30s

        local {
          auth = psk
          id = $LOCAL_PRIVATE_IP
        }

        remote {
          auth = psk
          id = $REMOTE_PRIVATE_IP
        }

        children {
          vip-ranges {
            local_ts = 0.0.0.0/0
            remote_ts = 0.0.0.0/0

            if_id_in = 42
            if_id_out = 42

            esp_proposals = aes256-sha256-modp2048

            start_action = start
            dpd_action = restart
          }
        }
      }
    }

    secrets {
      ike-f5xc-ce {
        id-1 = $LOCAL_PRIVATE_IP
        id-2 = $REMOTE_PRIVATE_IP
        secret = "$IPSEC_PSK"
      }
    }
    EOF
    install -m 0600 /etc/swanctl/conf.d/f5xc-ce.conf /etc/swanctl/swanctl.conf

    systemctl enable strongswan-starter
    if ! systemctl restart strongswan-starter; then
      systemctl status strongswan-starter --no-pager || true
      journalctl -u strongswan-starter --no-pager -n 100 || true
      exit 1
    fi

    for attempt in $(seq 1 30); do
      if swanctl --stats >/dev/null 2>&1; then
        if swanctl --load-all --file /etc/swanctl/swanctl.conf --noprompt; then
          swanctl --list-conns
          exit 0
        fi
        echo "StrongSwan VICI is ready, but swanctl config load failed on attempt $attempt"
      fi
      echo "Waiting for StrongSwan VICI socket, attempt $attempt"
      sleep 1
    done

    systemctl status strongswan-starter --no-pager || true
    journalctl -u strongswan-starter --no-pager -n 100 || true
    exit 1
- path: /etc/systemd/system/configure-xfrm-ipsec.service
  owner: root:root
  permissions: '0644'
  content: |
    [Unit]
    Description=Configure XFRM interface and StrongSwan connection
    After=network-online.target
    Wants=network-online.target

    [Service]
    Type=oneshot
    ExecStart=/bin/bash -x /usr/local/sbin/configure-xfrm-ipsec.sh
    RemainAfterExit=yes

    [Install]
    WantedBy=multi-user.target
- path: /etc/sysctl.d/99-tailscale-subnet-router.conf
  owner: root:root
  permissions: '0644'
  content: |
    net.ipv4.ip_forward=1
- path: /etc/systemd/system/frr.service.d/override.conf
  owner: root:root
  permissions: '0644'
  content: |
    [Unit]
    After=configure-xfrm-ipsec.service

runcmd:
 - mkdir -p /var/www/html
 - cp /tmp/nginx-index.html /var/www/html/index.html
 - cp /tmp/nginx-index.html /var/www/html/index.nginx-debian.html
 - systemctl restart nginx
 - curl -fsSL https://tailscale.com/install.sh | sh
 - systemctl daemon-reload
 - systemctl enable tailscaled
 - systemctl restart tailscaled
 - tailscale up --authkey '${tailscale_auth_key}' --hostname tailscale-subnet-router
 - systemctl enable configure-xfrm-ipsec.service
 - systemctl start configure-xfrm-ipsec.service
 - systemctl enable frr
 - systemctl restart frr
