resource "helm_release" "sentence-app" {
  name       = "sentence-app"
  repository = "https://gitlab.com/api/v4/projects/31458926/packages/helm/main"
  chart      = "sentence-app"
  version    = "0.5.0"

  values = [
    # "${file("values.yaml")}"
    "${templatefile("${path.module}/values.yaml", {
      namespace = data.terraform_remote_state.aks.outputs.aks-namespace
    })}"
  ]
}