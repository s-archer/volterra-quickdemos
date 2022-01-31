data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["netcubed/amd64/ubuntu-desktop-20.04*"]
  }
  owners = ["679593333241"] # netcubed
}

resource "aws_instance" "ubuntu" {
  ami                         = data.aws_ami.ubuntu.id
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
  depends_on = [
    aws_instance.ubuntu
  ]

  instance_tags = {
    Name  = "${var.prefix}-ubuntu"
    Env   = "ubuntu"
    UK-SE = var.uk_se
  }

  filter {
    name   = "subnet-id"
    values = [var.subnet]
  }
}