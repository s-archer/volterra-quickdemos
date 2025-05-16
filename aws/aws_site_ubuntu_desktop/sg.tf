resource "aws_security_group" "ubuntu" {
  name        = "mgmt"
  description = "Allow SSH and TLS inbound from within VPC"
  vpc_id      = aws_vpc.volt.id

  ingress {
    description = "SSH for mgmt"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  ingress {
    description = "TLS for mgmt"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mgmt"
  }
}
