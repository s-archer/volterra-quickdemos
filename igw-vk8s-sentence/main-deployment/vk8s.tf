resource "volterra_virtual_k8s" "vk8s" {
  name      = var.xc_vk8s_name
  namespace = var.xc_namespace

  vsite_refs {
    name      = var.xc_vk8s_virtual_site_name
    namespace = var.xc_vk8s_virtual_site_namespace
  }

  # provisioner "local-exec" {
  #   command     = "${path.module}/f5xc_resource_ready.py --type vk8s --name ${self.name} --ns ${self.namespace}"
  #   working_dir = "${path.module}/tmp"    
  #   environment = {
  #     VES_API_URL = var.xc_api_url
  #     VES_P12     = var.xc_api_p12_file
  #   }
  # }
}

resource "volterra_api_credential" "vk8s" {
  name      = "api-cred-example"
  api_credential_type = "KUBE_CONFIG"
  virtual_k8s_namespace = var.xc_namespace
  virtual_k8s_name = volterra_virtual_k8s.vk8s.name
}

resource "local_file" "rendered_kubeconfig" {
  content = base64decode(volterra_api_credential.vk8s.data)
  filename = "${path.module}/kubeconfig.yaml"
}