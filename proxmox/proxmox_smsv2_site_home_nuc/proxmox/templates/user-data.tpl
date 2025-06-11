#cloud-config
write_files:
  - path: /etc/vpm/user_data
    permissions: 644
    owner: root
    content: |
      token: ${token}
      #slo_ip: Un-comment and set Static IP/mask for SLO if needed.
      #slo_gateway: Un-comment and set default gateway for SLO when static IP is  needed.
runcmd:
  - [ sh, -c, test -e /usr/bin/fsextend  && /usr/bin/fsextend || true ]