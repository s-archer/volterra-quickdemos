output "cluster-endpoint" {
  value = aws_eks_cluster.eks.endpoint
}

output "cluster-name" {
  value = aws_eks_cluster.eks.name
}

output "aks-namespace" {
  value = var.aks_k8s_namespace
}

output "eks-namespace" {
  value = var.eks_k8s_namespace
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.eks.certificate_authority[0].data
}

# output "secret-data" {
#   value     = data.kubernetes_secret_v1.f5xc-secret.data.token
#   sensitive = true
# }