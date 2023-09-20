resource "volterra_api_credential" "vk8s-alt" {
  name      = "api-cred-example"
  api_credential_type = "KUBE_CONFIG"
  virtual_k8s_namespace = var.xc_namespace-colors
  virtual_k8s_name = var.xc_vk8s_alt_name
}

resource "local_file" "rendered_kubeconfig" {
  content = base64decode(volterra_api_credential.vk8s-alt.data)
  filename = "${path.module}/kubeconfig-alt.yaml"
}