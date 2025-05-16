output "region" {
  value       = var.gcp_region
  description = "GCloud Region"
}

output "project_id" {
  value       = var.project_id
  description = "GCloud Project ID"
}

output "kubernetes_cluster_name" {
  value       = google_container_cluster.primary.name
  description = "GKE Cluster Name"
}

output "kubernetes_cluster_host" {
  value       = google_container_cluster.primary.endpoint
  description = "GKE Cluster Host"
}

output "aks-namespace" {
  value = var.aks_k8s_namespace
}

output "eks-namespace" {
  value = var.eks_k8s_namespace
}

output "gke-namespace" {
  value = var.gke_k8s_namespace
}