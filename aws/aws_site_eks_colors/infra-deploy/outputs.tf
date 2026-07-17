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

output "secret-data" {
  value     = data.kubernetes_secret_v1.f5xc-secret.data.token
  sensitive = true
}

output "ssh-key-name" {
  value     = aws_key_pair.demo.key_name
  sensitive = true
}

output "vpc-id" {
  value     = aws_vpc.volt.id
  sensitive = true
}

output "subnet-id-worker" {
  value     = aws_subnet.eks_worker.id
  sensitive = true
}

output "aws-site-name" {
  value = var.site_name
}
