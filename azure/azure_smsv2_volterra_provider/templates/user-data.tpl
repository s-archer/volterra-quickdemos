#cloud-config
#Only values that need to be inserted are token and site name. Insert as is without parenthesis
write_files:
- path: /etc/hosts
  content: |
    # IPv4 and IPv6 localhost aliases 
    127.0.0.1 localhost
    127.0.0.1 vip
  permissions: 0644
  owner: root
- path: /etc/vpm/config.yaml
  permissions: 0644
  owner: root
  content: |
    Vpm:
      ClusterType: ce
      ClusterName: ${cluster_name}
      Token: ${token}
      MauricePrivateEndpoint: https://register-tls.ves.volterra.io
      MauriceEndpoint: https://register.ves.volterra.io
      CertifiedHardwareEndpoint: https://vesio.blob.core.windows.net/releases/certified-hardware/azure.yml
    Kubernetes:
      EtcdUseTLS: True
      Server: vip
      CloudProvider: disabled
