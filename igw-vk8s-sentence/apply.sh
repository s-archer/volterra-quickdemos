#!/bin/sh
terraform apply --auto-approve -target=volterra_api_credential.vk8s -target=local_file.rendered_kubeconfig
read -p "Press any key to apply remaining resources..."
terraform apply --auto-approve