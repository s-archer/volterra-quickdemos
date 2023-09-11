resource "aws_vpc" "volt" {
  cidr_block = "10.0.0.0/16"
  # ipv4_ipam_pool_id   = aws_vpc_ipam_pool.test.id
  # ipv4_netmask_length = 17
  # depends_on = [
  #   aws_vpc_ipam_pool_cidr.test
  # ]
  tags = {
    Name = "${var.prefix}vpc"
  }
}


resource "aws_subnet" "eks_outside" {
  cidr_block        = "10.0.101.0/24"
  availability_zone = local.azs[0]
  vpc_id            = aws_vpc.volt.id
  tags = {
    Name = "${var.prefix}outside"
  }
}

resource "aws_subnet" "eks_inside" {
  cidr_block        = "10.0.102.0/24"
  availability_zone = local.azs[0]
  vpc_id            = aws_vpc.volt.id
  tags = {
    Name = "${var.prefix}inside"
  }
}

resource "aws_subnet" "eks_worker" {
  cidr_block              = "10.0.103.0/24"
  map_public_ip_on_launch = true
  availability_zone       = local.azs[0]
  vpc_id                  = aws_vpc.volt.id
  tags = {
    Name = "${var.prefix}worker"
  }
}

resource "aws_subnet" "eks_control" {
  cidr_block              = "10.0.104.0/24"
  map_public_ip_on_launch = true
  availability_zone       = local.azs[0]
  vpc_id                  = aws_vpc.volt.id
  tags = {
    Name = "${var.prefix}control"
  }
}

resource "aws_subnet" "eks_data" {
  cidr_block              = "10.0.105.0/24"
  map_public_ip_on_launch = true
  availability_zone       = local.azs[0]
  vpc_id                  = aws_vpc.volt.id
  tags = {
    Name = "${var.prefix}data"
  }
}

resource "aws_subnet" "eks_outside_1" {
  cidr_block        = "10.0.111.0/24"
  availability_zone = local.azs[1]
  vpc_id            = aws_vpc.volt.id
  tags = {
    Name = "${var.prefix}outside_1"
  }
}

resource "aws_subnet" "eks_inside_1" {
  cidr_block        = "10.0.112.0/24"
  availability_zone = local.azs[1]
  vpc_id            = aws_vpc.volt.id
  tags = {
    Name = "${var.prefix}inside_1"
  }
}

resource "aws_subnet" "eks_worker_1" {
  cidr_block              = "10.0.113.0/24"
  map_public_ip_on_launch = true
  availability_zone       = local.azs[1]
  vpc_id                  = aws_vpc.volt.id
  tags = {
    Name = "${var.prefix}worker_1"
  }
}

resource "aws_subnet" "eks_control_1" {
  cidr_block              = "10.0.114.0/24"
  map_public_ip_on_launch = true
  availability_zone       = local.azs[1]
  vpc_id                  = aws_vpc.volt.id
  tags = {
    Name = "${var.prefix}control_1"
  }
}

resource "aws_subnet" "eks_data_1" {
  cidr_block              = "10.0.115.0/24"
  map_public_ip_on_launch = true
  availability_zone       = local.azs[1]
  vpc_id                  = aws_vpc.volt.id
  tags = {
    Name = "${var.prefix}data_1"
  }
}

resource "aws_subnet" "eks_outside_2" {
  cidr_block        = "10.0.121.0/24"
  availability_zone = local.azs[2]
  vpc_id            = aws_vpc.volt.id
  tags = {
    Name = "${var.prefix}outside_2"
  }
}

resource "aws_subnet" "eks_inside_2" {
  cidr_block        = "10.0.122.0/24"
  availability_zone = local.azs[2]
  vpc_id            = aws_vpc.volt.id
  tags = {
    Name = "${var.prefix}inside_2"
  }
}

resource "aws_subnet" "eks_worker_2" {
  cidr_block              = "10.0.123.0/24"
  map_public_ip_on_launch = true
  availability_zone       = local.azs[2]
  vpc_id                  = aws_vpc.volt.id
  tags = {
    Name = "${var.prefix}worker_2"
  }
}

resource "aws_subnet" "eks_control_2" {
  cidr_block              = "10.0.124.0/24"
  map_public_ip_on_launch = true
  availability_zone       = local.azs[2]
  vpc_id                  = aws_vpc.volt.id
  tags = {
    Name = "${var.prefix}control_2"
  }
}

resource "aws_subnet" "eks_data_2" {
  cidr_block              = "10.0.125.0/24"
  map_public_ip_on_launch = true
  availability_zone       = local.azs[2]
  vpc_id                  = aws_vpc.volt.id
  tags = {
    Name = "${var.prefix}data_2"
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

# resource "aws_route_table_association" "eks_outside" {
#   subnet_id      = aws_subnet.eks_outside.id
#   route_table_id = aws_vpc.volt.default_route_table_id
# }

# resource "aws_route_table_association" "eks_inside" {
#   subnet_id      = aws_subnet.eks_inside.id
#   route_table_id = aws_vpc.volt.default_route_table_id
# }

# resource "aws_route_table_association" "eks_outside_1" {
#   subnet_id      = aws_subnet.eks_outside_1.id
#   route_table_id = aws_vpc.volt.default_route_table_id
# }

# resource "aws_route_table_association" "eks_inside_1" {
#   subnet_id      = aws_subnet.eks_inside_1.id
#   route_table_id = aws_vpc.volt.default_route_table_id
# }

# resource "aws_route_table_association" "eks_outside_2" {
#   subnet_id      = aws_subnet.eks_outside_2.id
#   route_table_id = aws_vpc.volt.default_route_table_id
# }

# resource "aws_route_table_association" "eks_inside_2" {
#   subnet_id      = aws_subnet.eks_inside_2.id
#   route_table_id = aws_vpc.volt.default_route_table_id
# }