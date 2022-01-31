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

resource "aws_autoscaling_group" "nginx" {
  name                 = "${var.prefix}nginx-asg"
  launch_configuration = aws_launch_configuration.nginx.name
  desired_capacity     = var.desired_capacity
  min_size             = 1
  max_size             = 4
  vpc_zone_identifier  = var.subnets

  lifecycle {
    create_before_destroy = true
  }

  tags = [
    {
      key                 = "Name"
      value               = "${var.uk_se}-nginx-autoscale"
      propagate_at_launch = true
    },
    {
      key                 = "Env"
      value               = "consul"
      propagate_at_launch = true
    },
    {
      key                 = "UK-SE"
      value               = var.uk_se
      propagate_at_launch = true
    }
  ]

}

resource "aws_launch_configuration" "nginx" {
  name_prefix                 = "${var.prefix}-nginx-"
  image_id                    = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  associate_public_ip_address = false

  security_groups      = var.security_groups
  key_name             = var.key_name
  user_data            = file("${path.module}/scripts/nginx.sh")
  iam_instance_profile = aws_iam_instance_profile.nginx.name


  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy" "nginx" {
  name = "${var.prefix}nginx-policy"
  role = aws_iam_role.nginx.id

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

resource "aws_iam_role" "nginx" {
  name = "${var.prefix}nginx"

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

resource "aws_iam_instance_profile" "nginx" {
  name = "${var.prefix}nginx"
  role = aws_iam_role.nginx.name
}