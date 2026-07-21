#cloud-config
packages:
 - curl
 - nginx

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
      <title>Azure Region: ${azure_region}</title>
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
        <h1>NGINX on Azure</h1>
        <p>server <strong>${server_number}</strong></p>
        <p>Serving from Azure region <strong>${azure_region}</strong></p>
      </main>
    </body>
    </html>

runcmd:
 - mkdir -p /var/www/html
 - cp /tmp/nginx-index.html /var/www/html/index.html
 - cp /tmp/nginx-index.html /var/www/html/index.nginx-debian.html
 - systemctl restart nginx
 - curl -fsSL https://tailscale.com/install.sh | sh
%{ if tailscale_auth_key != "" ~}
 - systemctl enable tailscaled
 - systemctl restart tailscaled
 - tailscale up --authkey '${tailscale_auth_key}' --hostname '${tailscale_hostname}'
%{ endif ~}
