# module "vpc" {
#   source          = "terraform-aws-modules/vpc/aws"
#   count           = var.vpc-count
#   name            = "arch-tgw-${count.index}-vpc"
#   cidr            = "10.${count.index}.0.0/16"
#   manage_default_route_table = true
#   azs             = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
#   public_subnets  = [
#     "10.${count.index}.1.0/24", 
#     "10.${count.index}.2.0/24", 
#     "10.${count.index}.3.0/24"
#   ]
#   # Subnet order: outside, inside, workload
#   private_subnets = [
#     "10.${count.index}.11.0/24", 
#     "10.${count.index}.12.0/24", 
#     "10.${count.index}.13.0/24", 
#     "10.${count.index}.21.0/24",  
#     "10.${count.index}.22.0/24", 
#     "10.${count.index}.23.0/24", 
#   ]
#   tags = {
#     Terraform   = "true"
#     Environment = "dev"
#     uk_se       = var.uk_se_name

#   }
# }

resource "aws_vpc" "tgw" {
  count            = var.vpc-count
  cidr_block       = "10.${count.index}.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name  = "arch-tgw-${count.index}-vpc"
    UK-SE = var.uk_se_name
  }
}

# resource "aws_internet_gateway" "igw" {
#   vpc_id = aws_vpc.tgw[0].id

#   tags = {
#     Name  = "arch-tgw-0-igw"
#     UK-SE = var.uk_se_name
#   }
# }


# CREATE SUBNET FOR OUTSIDE
resource "aws_subnet" "outside" {
  count             = local.subnet-count
  vpc_id            = aws_vpc.tgw[count.index % var.vpc-count].id
  cidr_block        = format("10.%s.%s%s.0/24", tostring(count.index % var.vpc-count), tostring((count.index % var.vpc-count) + 1), tostring(ceil(count.index / var.vpc-count)))
  # availability_zone = local.azs[count.index % length(local.azs)]
  availability_zone = local.azs[floor(count.index / length(local.azs))]

  tags = {
    Name  = format("vpc%s-outside-%s", tostring(count.index % var.vpc-count), var.azs_short[(floor(count.index / var.vpc-count))])
    UK-SE = var.uk_se_name
  }
}


# CREATE SUBNET FOR INSIDE
resource "aws_subnet" "inside" {
  count             = local.subnet-count
  vpc_id            = aws_vpc.tgw[count.index % var.vpc-count].id
  cidr_block        = format("10.%s.%s%s%s.0/24", tostring(count.index % var.vpc-count), "1", tostring((count.index % var.vpc-count) + 1), tostring(ceil(count.index / var.vpc-count)))
  availability_zone = local.azs[floor(count.index / length(local.azs))]

  tags = {
    Name  = format("vpc%s-inside-%s", tostring(count.index % var.vpc-count), var.azs_short[(floor(count.index / var.vpc-count))])
    UK-SE = var.uk_se_name
  }
}

# CREATE SUBNET FOR WORKER
resource "aws_subnet" "worker" {
  count             = local.subnet-count
  vpc_id            = aws_vpc.tgw[count.index % var.vpc-count].id
  cidr_block        = format("10.%s.%s%s%s.0/24", tostring(count.index % var.vpc-count), "2", tostring((count.index % var.vpc-count) + 1), tostring(ceil(count.index / var.vpc-count)))
  availability_zone = local.azs[floor(count.index / length(local.azs))]

  tags = {
    Name  = format("vpc%s-worker-%s", tostring(count.index % var.vpc-count), var.azs_short[(floor(count.index / var.vpc-count))])
    UK-SE = var.uk_se_name
  }
}