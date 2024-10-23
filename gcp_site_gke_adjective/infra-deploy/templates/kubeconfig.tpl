apiVersion: v1
kind: Config
clusters:
- name: default-cluster
  cluster:
    certificate-authority-data: ${cluster_ca_certificate}
    server: ${endpoint}
contexts:
- name: default-context
  context:
    cluster: default-cluster
    user: default-user
current-context: default-context
users:
- name: default-user
  user:
    auth-provider:
      config:
        access-token: ${token}
      name: gcp
