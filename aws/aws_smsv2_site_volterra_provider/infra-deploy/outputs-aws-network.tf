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
