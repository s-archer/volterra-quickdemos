data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "consul" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.medium"
  private_ip                  = "10.0.103.100"
  subnet_id                   = var.subnet
  vpc_security_group_ids      = var.security_groups
  user_data                   = file("${path.module}/scripts/consul.sh")
  iam_instance_profile        = aws_iam_instance_profile.consul.name
  key_name                    = var.key_name
  tags = {
    Name  = "${var.prefix}consul"
    Env   = "consul"
    UK-SE = var.uk_se
  }
}

resource "aws_iam_role_policy" "consul" {
  name = "f5-consul-policy"
  role = aws_iam_role.consul.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeTags",
        "autoscaling:DescribeAutoScalingGroups"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "consul" {
  name = "f5-consul"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "consul" {
  name = "f5-consul"
  role = aws_iam_role.consul.name
}