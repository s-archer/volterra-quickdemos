# data "aws_ami" "ubuntu" {
#   most_recent = true

#   filter {
#     name   = "name"
#     values = ["netcubed/amd64/ubuntu-desktop-20.04*"]
#   }
#   owners = ["679593333241"] # netcubed
# }

# Note that I have commented out above because AWS no longer returns images older than two years using the AMI API.check "
# Had to hard-code the AMI for the eu-west-1 region below.

resource "aws_instance" "ubuntu" {
  #ami                         = data.aws_ami.ubuntu.id
  ami                         = "ami-09f9978f467778b47"
  instance_type               = "t2.medium"
  private_ip                  = "10.0.103.100"
  subnet_id                   = var.subnet
  vpc_security_group_ids      = var.security_groups
  user_data                   = templatefile("${path.module}/scripts/ubuntu.sh", {
    volt_ip                   = var.volt_ip
  })
  key_name                    = var.key_name
  tags = {
    Name  = "${var.prefix}-ubuntu"
    Env   = "ubuntu"
    UK-SE = var.uk_se
  }
}

data "aws_instances" "ubuntu" {
  # depends_on = [
  #   aws_instance.ubuntu
  # ]

  instance_tags = {
    #Name  = "${var.prefix}-ubuntu"
    Name  = aws_instance.ubuntu.tags_all["Name"]
    Env   = "ubuntu"
    UK-SE = var.uk_se
  }

  filter {
    name   = "subnet-id"
    values = [var.subnet]
  }
}