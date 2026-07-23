resource "aws_security_group" "mgmt" {
  name        = "${var.prefix}mgmt"
  description = "Allow SSH and TLS inbound traffic"
  vpc_id      = aws_vpc.f5xc.id

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

resource "aws_security_group" "outside" {
  name        = "${var.prefix}outside"
  description = "Allow outbound only"
  vpc_id      = aws_vpc.f5xc.id

  ingress {
    # Aloow Site Mesh Group to form over Internet
    description = "Allow IPSec from anywhere"
    from_port   = 4500
    to_port     = 4500
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow IKE for IPSec from anywhere"
    from_port   = 500
    to_port     = 500
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow ESP for IPSec from anywhere"
    from_port   = 0
    to_port     = 0
    protocol    = 50
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${data.http.myip.response_body}/32", "10.0.0.0/16", "62.194.187.64/32", "1.6.0.0/16", "15.110.0.0/16", "111.92.121.65/32"]
    # cidr_blocks = ["10.0.0.0/16"]
  }
  # Allow VPN tunnel for external connector
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
    # cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    from_port   = 65500
    to_port     = 65500
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.response_body)}/32"]
    # cidr_blocks = ["10.0.0.0/16"]
  }

  # === EGRESS RULES (from F5 XC documentation) ===

  # Allow All (for debug)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # # All Geographies - Global F5 Service
  # egress {
  #   description = "All Geographies TCP 443"
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   cidr_blocks = ["159.60.141.140/32"]
  # }

  # # Europe TCP (HTTP/HTTPS)
  # egress {
  #   description = "Europe TCP 80"
  #   from_port   = 80
  #   to_port     = 80
  #   protocol    = "tcp"
  #   cidr_blocks = local.xc_egress_re_cidrs
  # }

  # egress {
  #   description = "Europe TCP 443"
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   cidr_blocks = local.all_egress_cidrs
  # }

  # # Europe UDP (IPSec / NTP)
  # egress {
  #   description = "Europe UDP 4500"
  #   from_port   = 4500
  #   to_port     = 4500
  #   protocol    = "udp"
  #   cidr_blocks = local.xc_egress_re_cidrs
  # }

  # egress {
  #   description = "Europe UDP 123"
  #   from_port   = 123
  #   to_port     = 123
  #   protocol    = "udp"
  #   cidr_blocks = local.xc_egress_re_cidrs
  # }

  # # DNS (Google Public DNS)
  # egress {
  #   description = "DNS TCP 53"
  #   from_port   = 53
  #   to_port     = 53
  #   protocol    = "tcp"
  #   cidr_blocks = ["8.8.8.8/32", "8.8.4.4/32"]
  # }

  # egress {
  #   description = "DNS UDP 53"
  #   from_port   = 53
  #   to_port     = 53
  #   protocol    = "udp"
  #   cidr_blocks = ["8.8.8.8/32", "8.8.4.4/32"]
  # }

  tags = {
    Name  = "${var.prefix}external",
    UK-SE = var.uk_se_name
  }
}


resource "aws_security_group" "internal" {
  name        = "${var.prefix}internal"
  description = "Allow HTTP and HTTPS inbound traffic"
  vpc_id      = aws_vpc.f5xc.id

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

resource "aws_security_group" "inside" {
  name        = "${var.prefix}inside"
  description = "Allow HTTP and HTTPS inbound traffic"
  vpc_id      = aws_vpc.f5xc.id

  # ingress {
  #   description = "HTTP"
  #   from_port   = 80
  #   to_port     = 80
  #   protocol    = "tcp"
  #   cidr_blocks = ["10.0.0.0/16"]
  # }

  # ingress {
  #   description = "HTTPS"
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   cidr_blocks = ["10.0.0.0/16"]
  # }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "${var.prefix}inside",
    UK-SE = var.uk_se_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "eks-in" {
  security_group_id = aws_eks_cluster.eks.vpc_config[0].cluster_security_group_id

  cidr_ipv4   = "10.0.0.0/16"
  ip_protocol = "-1"
  description = "allow any inbound to cluster"
}
