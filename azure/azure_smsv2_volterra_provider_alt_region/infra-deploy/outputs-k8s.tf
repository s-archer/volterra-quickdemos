output "aks-namespace" {
  value = var.aks_k8s_namespace
}

output "eks-namespace" {
  value = var.eks_k8s_namespace
}

output "message" {
  value = "Now cd ../helm and tfa to deploy the sentence app containers"
}
