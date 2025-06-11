resource "kubernetes_namespace" "arcadiacrypto" {
  metadata {
    name = "arcadiacrypto"
  }
}

resource "kubernetes_manifest" "manifests" {
  for_each = data.local_file.manifest

  manifest = yamldecode(each.value.content)
}

locals {
  manifest_files = fileset("${path.module}/k8s-manifests", "*.yaml")
}

# Load each manifest as a local_file data source
data "local_file" "manifest" {
  for_each = { for file in local.manifest_files : file => file }

  filename = "${path.module}/k8s-manifests/${each.value}"
}

# Replaced this ollama container with a VM using GPUs
# resource "kubernetes_job" "ollama_pull_model" {
#   # This job pulls the llama2 model from Ollama when Ollama is ready.
#   # The ollama container does not have the model preloaded, so we need to pull it.
#   depends_on = [kubernetes_manifest.manifests]
#   metadata {
#     name = "ollama-pull-model"
#   }

#   spec {
#     template {
#       metadata {
#         labels = {
#           job = "ollama-pull-model"
#         }
#       }

#       spec {
#         restart_policy = "OnFailure"

#         container {
#           name  = "model-puller"
#           image = "curlimages/curl:latest"

#           command = ["sh", "-c"]

#           args = [
#             <<-EOT
#               echo "Waiting for Ollama to be ready...";
#               until curl -sf ollama.arcadiacrypto.svc.cluster.local:11434; do sleep 2; done;
#               echo "Pulling llama3.2...";
#               curl -X POST ollama.arcadiacrypto.svc.cluster.local:11434/api/pull -H "Content-Type: application/json" -d '{"name": "llama3.2"}';
#             EOT
#           ]
#         }
#       }
#     }
#   }
# }