resource "helm_release" "sentence-app" {
  name       = "sentence-app"
  repository = "https://gitlab.com/api/v4/projects/31458926/packages/helm/main"
  chart      = "sentence-app"

  values = [
    "${file("values.yaml")}"
  ]
}