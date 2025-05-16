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

resource "aws_instance" "nginx" {
  count = 2
  # subnet_id     = format("vpc%s-worker-a", tostring(count.index + 1))
  subnet_id     = aws_subnet.worker[count.index +1].id
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.demo.key_name
  security_groups = [aws_security_group.nginx[count.index].id]
  user_data     = file("${path.module}/scripts/nginx.sh")
  tags = {
    Name = "arch-nginx-${count.index + 1}"
  }
}