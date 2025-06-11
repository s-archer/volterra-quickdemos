data "aws_ami" "amazon_linux_gpu" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-gpu-hvm-2.0.*-x86_64-ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "instance_sg" {
  name        = "g4dn-instance-sg"
  description = "Security group for G4DN instance"
  vpc_id      = data.terraform_remote_state.eks.outputs.vpc-id

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  ingress {
    description = "HTTP access"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  ingress {
    description = "Ollama API access"
    from_port   = 11434
    to_port     = 11434
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
    Name = "g4dn-sg"
  }
}

resource "aws_instance" "ollama" {
  ami           = data.aws_ami.amazon_linux_gpu.id
  instance_type = var.instance_type

  subnet_id                   = data.terraform_remote_state.eks.outputs.subnet-id-worker
  vpc_security_group_ids      = [aws_security_group.instance_sg.id]
  associate_public_ip_address = true
  key_name                   = data.terraform_remote_state.eks.outputs.ssh-key-name

  root_block_device {
    volume_size = 100  # GB
    volume_type = "gp3"
  }

  # Provide the setup.sh script as user data
  user_data = templatefile("${path.module}/templates/user-data.tpl", {

  })

  tags = {
    Name = "arch-ollama-g4dn-instance"
  }
}