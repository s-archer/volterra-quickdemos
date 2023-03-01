output "cluster-endpoint" {
  value = aws_eks_cluster.arch-eks.endpoint
}

output "cluster-name" {
  value = aws_eks_cluster.arch-eks.name
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.arch-eks.certificate_authority[0].data
}

output "secret-data" {
  value     = data.kubernetes_secret_v1.f5xc-secret-xxx.data.token
  sensitive = true
}