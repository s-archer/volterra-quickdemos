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
    cidr_blocks = ["${data.http.myip.response_body}/32", "10.0.0.0/16", "62.194.187.64/32", "1.6.0.0/16", "15.110.0.0/16", "111.92.121.65/32"]
    #cidr_blocks = ["0.0.0.0/0"]
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


resource "aws_security_group" "internal" {
  name        = "${var.prefix}internal"
  description = "Allow HTTP and HTTPS inbound traffic"
  vpc_id      = data.terraform_remote_state.eks.outputs.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
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