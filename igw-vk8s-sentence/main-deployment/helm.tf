resource "helm_release" "sentence-app" {
  depends_on = [local_file.rendered_kubeconfig]
  name       = "sentence-app"
  repository = "https://gitlab.com/api/v4/projects/31458926/packages/helm/main"
  chart      = "sentence-app"
  version    = "0.6.0"
  wait       = false

  values = [
    # "${file("values.yaml")}"
    "${templatefile("${path.module}/values.yaml", {
      namespace = var.xc_namespace
    })}"
  ]
}