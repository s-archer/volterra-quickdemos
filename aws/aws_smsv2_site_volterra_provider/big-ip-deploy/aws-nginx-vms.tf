data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name = "name"
    # values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
    values = ["al2023-ami-ecs-hvm-2023*x86*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  #owners = ["099720109477"] # Canonical
  owners = ["591542846629"] # AWS
}

# resource "aws_eip" "nginx_nat_gateway" {
#   domain = "vpc"
#   tags = {
#     Name  = "${var.prefix}nginx_nat_gateway_eip"
#     UK-SE = "arch"
#   }
# }

# resource "aws_nat_gateway" "nginx" {
#   allocation_id = aws_eip.nginx_nat_gateway.id
#   subnet_id     = data.terraform_remote_state.eks.outputs.subnet_id_bip_outside

#   tags = {
#     Name  = "${var.prefix}nginx_nat_gateway"
#     UK-SE = "arch"
#   }
# }

# resource "aws_route" "internal" {
#   route_table_id         = data.terraform_remote_state.eks.outputs.route_table_id
#   destination_cidr_block = "0.0.0.0/0"
#   nat_gateway_id         = aws_nat_gateway.nginx.id
# }


resource "aws_launch_template" "nginx" {
  name_prefix   = "${var.prefix}nginx-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  key_name      = aws_key_pair.demo.key_name
  user_data     = filebase64("./scripts/nginx.sh")
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.nginx.id]
  }
}

resource "aws_autoscaling_group" "nginx" {
  name                = "${var.prefix}nginx-asg"
  desired_capacity    = 2
  min_size            = 1
  max_size            = 4
  vpc_zone_identifier = [data.terraform_remote_state.eks.outputs.subnet_id_bip_inside]
  # depends_on          = [aws_route.internal]

  lifecycle {
    create_before_destroy = true
  }

  launch_template {
    id      = aws_launch_template.nginx.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.prefix}nginx-autoscale"
    propagate_at_launch = true
  }

  tag {
    key                 = "Env"
    value               = "aws"
    propagate_at_launch = true
  }
}