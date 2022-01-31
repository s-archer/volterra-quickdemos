resource "aws_vpc" "volt" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "${var.prefix}vpc"
  }
}

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