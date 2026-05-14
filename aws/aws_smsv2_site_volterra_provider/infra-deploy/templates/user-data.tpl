#cloud-config
write_files:
- path: /etc/vpm/user_data
  content: |
    token: ${token}
  owner: root
  permissions: '0644'
