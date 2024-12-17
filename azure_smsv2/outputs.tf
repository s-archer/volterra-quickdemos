output "secure_mesh_site" {
  value = {
    site = restful_resource.site[*].output
    token = {
      key       = restful_resource.token[*].output.spec.content
      type      = restful_resource.token[*].output.spec.type
      state     = restful_resource.token[*].output.spec.state
      algorithm = local.algorithm
    }
  }
}

output "ssh_f5_username" {
  value = "volterra-admin"
}

output "ssh_f5_password" {
  value = random_string.password.result
}

output "ssh_f5-1" {
  value = "ssh admin@${azurerm_public_ip.outside_public_ip[0].ip_address}"
}