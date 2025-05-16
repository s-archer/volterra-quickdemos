output "vpc_list" {
  value = [formatlist("%s %s", aws_vpc.tgw[*].tags.Name, aws_vpc.tgw[*].id)]
}

output "outside_subnet_list" {
  value = [
    for v in aws_vpc.tgw : [
      for s in aws_subnet.outside : format("%s %s %s", s.tags.Name, s.availability_zone, s.id) if s.vpc_id == v.id
    ]
  ]
}

output "inside_subnet_list" {
  value = [
    for v in aws_vpc.tgw : [
      for s in aws_subnet.inside : format("%s %s %s", s.tags.Name, s.availability_zone, s.id) if s.vpc_id == v.id
    ]
  ]
}

output "worker_subnet_list" {
  value = [
    for v in aws_vpc.tgw : [
      for s in aws_subnet.worker : format("%s %s %s", s.tags.Name, s.availability_zone, s.id) if s.vpc_id == v.id
    ]
  ]
}

output "ce_node_subnets" {
  value = [ 
    [
      "node-1",
      format("%s %s %s", aws_subnet.outside[0].id, aws_subnet.outside[0].availability_zone, aws_subnet.outside[0].vpc_id),
      format("%s %s %s", aws_subnet.inside[0].id, aws_subnet.inside[0].availability_zone, aws_subnet.inside[0].vpc_id),
      format("%s %s %s", aws_subnet.worker[0].id, aws_subnet.worker[0].availability_zone, aws_subnet.worker[0].vpc_id),
    ],
    [
      "node-2",
      format("%s %s %s", aws_subnet.outside[3].id, aws_subnet.outside[3].availability_zone, aws_subnet.outside[3].vpc_id),
      format("%s %s %s", aws_subnet.inside[3].id, aws_subnet.inside[3].availability_zone, aws_subnet.inside[3].vpc_id),
      format("%s %s %s", aws_subnet.worker[3].id, aws_subnet.worker[3].availability_zone, aws_subnet.worker[3].vpc_id),
    ],
    [
      "node-3",
      format("%s %s %s", aws_subnet.outside[6].id, aws_subnet.outside[6].availability_zone, aws_subnet.outside[6].vpc_id),
      format("%s %s %s", aws_subnet.inside[6].id, aws_subnet.inside[6].availability_zone, aws_subnet.inside[6].vpc_id),
      format("%s %s %s", aws_subnet.worker[6].id, aws_subnet.worker[6].availability_zone, aws_subnet.worker[6].vpc_id),
    ]
  ]
}