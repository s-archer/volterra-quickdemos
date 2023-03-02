apiVersion: v1
kind: Config
clusters:
- name: ${cluster_name}
  cluster:
    certificate-authority-data: ${ca_crt}  
    server: ${server}
contexts:
- name: ${sa_name}-${cluster_name}
  context:
    cluster: ${cluster_name}
    user: ${sa_name}
users:
- name: ${sa_name}
  user:
    token: ${token}
current-context: ${sa_name}-${cluster_name}