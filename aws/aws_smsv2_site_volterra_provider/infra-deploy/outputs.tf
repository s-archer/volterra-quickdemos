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

output "site-name" {
  value = volterra_securemesh_site_v2.site[0].name
}

output "virtual-site-name" {
  value = local.f5xc_sms_name
}

output "virtual-site-namespace" {
  value = volterra_virtual_site.ce.namespace
}

# output "kubeconfig-certificate-authority-data" {
#   value = aws_eks_cluster.eks.certificate_authority[0].data
# }

output "ssh-access" {
  value = (
    length(aws_eip.f5xc-outside) == 0
    ? ["n/a"]
    : [for count in range(length(aws_eip.f5xc-outside)) : "ssh admin@${aws_eip.f5xc-outside[count].public_ip} -i ./ssh-key.pem"]
  )
}

# output "secret-data" {
#   value     = data.kubernetes_secret_v1.f5xc-secret.data.token
#   sensitive = true
# }

output "vpc_id" {
  value = aws_vpc.f5xc.id
}

output "subnet_id_bip_mgmt" {
  value = aws_subnet.eks_bip_mgmt[0].id
}
output "subnet_id_bip_outside" {
  value = aws_subnet.eks_bip_outside[0].id
}
output "subnet_id_bip_inside" {
  value = aws_subnet.eks_bip_inside[0].id
}
output "subnet_id_ce_inside" {
  value = aws_subnet.eks_inside[0].id
}
output "internal_gw" {
  value = cidrhost(aws_subnet.eks_bip_inside[0].cidr_block, 1)
}
output "route_table_id" {
  value = aws_vpc.f5xc.default_route_table_id
}
output "prefix" {
  value = var.prefix
}