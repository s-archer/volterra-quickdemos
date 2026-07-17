data "http" "myip" {
  url = "https://ifconfig.me/ip"
}

resource "aws_security_group" "mgmt" {
  name        = "${var.prefix}mgmt"
  description = "Allow SSH and TLS inbound traffic"
  vpc_id      = data.terraform_remote_state.eks.outputs.vpc_id

  ingress {
    description = "SSH for mgmt"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${data.http.myip.response_body}/32"]
    #cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TLS for mgmt"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    #cidr_blocks = ["${data.http.myip.response_body}/32"]
    # Include GCP us-east-1 cidr blocks for Gitlab runners
    # cidr_blocks = ["${data.http.myip.response_body}/32", "34.0.0.0/8","35.0.0.0/8", "104.196.0.0/16", "162.216.148.0/22"]
    # cidr_blocks = ["0.0.0.0/0"]
    cidr_blocks = ["${data.http.myip.response_body}/32", "10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "${var.prefix}mgmt",
    UK-SE = var.uk_se_name
  }
}

resource "aws_security_group" "external" {
  name        = "${var.prefix}external"
  description = "Allow HTTP and HTTPS inbound traffic"
  vpc_id      = data.terraform_remote_state.eks.outputs.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name  = "${var.prefix}external",
    UK-SE = var.uk_se_name
  }
}

resource "aws_security_group" "internal" {
  name        = "${var.prefix}internal"
  description = "Allow HTTP and HTTPS inbound traffic"
  vpc_id      = data.terraform_remote_state.eks.outputs.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name  = "${var.prefix}external",
    UK-SE = var.uk_se_name
  }
}

resource "aws_security_group" "nginx" {
  name   = "${var.prefix}-nginx"
  vpc_id = data.terraform_remote_state.eks.outputs.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.response_body)}/32"]
    #cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    #cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8300
    to_port     = 8300
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    from_port   = 8301
    to_port     = 8301
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "${var.prefix}nginx",
    UK-SE = var.uk_se_name
  }

}