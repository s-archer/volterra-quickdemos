resource "aws_vpc" "volt" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "${var.prefix}vpc"
  }
}

# resource "aws_vpc_dhcp_options" "volt_dns_resolver" {
#   depends_on      = [volterra_tf_params_action.site]
#   domain_name_servers = [one(data.aws_instances.volt.private_ips)]
# }

# resource "aws_vpc_dhcp_options_association" "dns_resolver" {
#   vpc_id          = aws_vpc.volt.id
#   dhcp_options_id = aws_vpc_dhcp_options.volt_dns_resolver.id
# }

resource "aws_subnet" "volterra_outside" {
  cidr_block        = "10.0.101.0/24"
  availability_zone = local.azs[0]
  vpc_id            = aws_vpc.volt.id
  tags = {
    Name = "${var.prefix}outside"
  }
}

resource "aws_subnet" "volterra_inside" {
  cidr_block        = "10.0.102.0/24"
  availability_zone = local.azs[0]
  vpc_id            = aws_vpc.volt.id
  tags = {
    Name = "${var.prefix}inside"
  }
}

resource "aws_subnet" "volterra_worker" {
  cidr_block        = "10.0.103.0/24"
  availability_zone = local.azs[0]
  vpc_id            = aws_vpc.volt.id
  tags = {
    Name = "${var.prefix}worker"
  }
}

resource "aws_subnet" "volterra_outside_1" {
  cidr_block        = "10.0.111.0/24"
  availability_zone = local.azs[1]
  vpc_id            = aws_vpc.volt.id
  tags = {
    Name = "${var.prefix}outside_1"
  }
}

resource "aws_subnet" "volterra_inside_1" {
  cidr_block        = "10.0.112.0/24"
  availability_zone = local.azs[1]
  vpc_id            = aws_vpc.volt.id
  tags = {
    Name = "${var.prefix}inside_1"
  }
}

resource "aws_subnet" "volterra_worker_1" {
  cidr_block        = "10.0.113.0/24"
  availability_zone = local.azs[1]
  vpc_id            = aws_vpc.volt.id
  tags = {
    Name = "${var.prefix}worker_1"
  }
}

resource "aws_subnet" "volterra_outside_2" {
  cidr_block        = "10.0.121.0/24"
  availability_zone = local.azs[2]
  vpc_id            = aws_vpc.volt.id
  tags = {
    Name = "${var.prefix}outside_2"
  }
}

resource "aws_subnet" "volterra_inside_2" {
  cidr_block        = "10.0.122.0/24"
  availability_zone = local.azs[2]
  vpc_id            = aws_vpc.volt.id
  tags = {
    Name = "${var.prefix}inside_2"
  }
}

resource "aws_subnet" "volterra_worker_2" {
  cidr_block        = "10.0.123.0/24"
  availability_zone = local.azs[2]
  vpc_id            = aws_vpc.volt.id
  tags = {
    Name = "${var.prefix}worker_2"
  }
}

resource "aws_internet_gateway" "volt" {
  vpc_id = aws_vpc.volt.id

  tags = {
    Name = "${var.prefix}igw"
  }
}

resource "aws_default_route_table" "default" {
  default_route_table_id = aws_vpc.volt.default_route_table_id

  route {
    gateway_id = aws_internet_gateway.volt.id
    cidr_block = "0.0.0.0/0"
  }

  tags = {
    Name = "defult rt"
  }
}

resource "aws_route_table_association" "volterra_outside" {
  subnet_id      = aws_subnet.volterra_outside.id
  route_table_id = aws_vpc.volt.default_route_table_id
}

resource "aws_route_table_association" "volterra_inside" {
  subnet_id      = aws_subnet.volterra_inside.id
  route_table_id = aws_vpc.volt.default_route_table_id
}

resource "aws_route_table_association" "volterra_outside_1" {
  subnet_id      = aws_subnet.volterra_outside_1.id
  route_table_id = aws_vpc.volt.default_route_table_id
}

resource "aws_route_table_association" "volterra_inside_1" {
  subnet_id      = aws_subnet.volterra_inside_1.id
  route_table_id = aws_vpc.volt.default_route_table_id
}

resource "aws_route_table_association" "volterra_outside_2" {
  subnet_id      = aws_subnet.volterra_outside_2.id
  route_table_id = aws_vpc.volt.default_route_table_id
}

resource "aws_route_table_association" "volterra_inside_2" {
  subnet_id      = aws_subnet.volterra_inside_2.id
  route_table_id = aws_vpc.volt.default_route_table_id
}