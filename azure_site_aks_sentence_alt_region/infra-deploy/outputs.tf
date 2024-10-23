output "aks-namespace" {
  value = var.aks_k8s_namespace
}

output "message" {
  value = "Now cd ../helm and tfa to deploy the sentence app containers"
}

output "nginx_app_gw_ip" {
  value = azurerm_public_ip.nginx-app-gw.ip_address
}

output "nginx_app_gw_fqdn" {
  value = azurerm_public_ip.nginx-app-gw.fqdn
}