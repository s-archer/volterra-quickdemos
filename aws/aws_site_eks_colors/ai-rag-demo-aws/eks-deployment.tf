resource "kubernetes_namespace" "arcadiacrypto" {
  metadata {
    name = "arcadiacrypto"
  }
}

locals {
  manifest_files = fileset("${path.module}/k8s-manifests", "*.yaml")
}

data "local_file" "manifest" {
  for_each = { for file in local.manifest_files : file => file }

  filename = "${path.module}/k8s-manifests/${each.value}"
}

resource "kubernetes_manifest" "manifests" {
  for_each = data.local_file.manifest

  manifest = yamldecode(each.value.content)
}