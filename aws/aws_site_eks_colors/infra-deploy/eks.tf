resource "aws_eks_cluster" "eks" {
  name     = "${var.prefix}cluster"
  role_arn = aws_iam_role.eks-cluster-role.arn

  vpc_config {
    subnet_ids = [aws_subnet.eks_control.id, aws_subnet.eks_control_1.id, aws_subnet.eks_control_2.id]
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.eks-cluster-attach-0,
    aws_iam_role_policy_attachment.eks-cluster-attach-1,
  ]
  tags = {
    Name  = "${var.prefix}cluster"
    owner = var.uk_se_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "eks-in" {
  security_group_id = aws_eks_cluster.eks.vpc_config[0].cluster_security_group_id

  cidr_ipv4   = "10.0.0.0/16"
  ip_protocol = "-1"
  description = "allow any inbound to cluster"
}

resource "aws_eks_node_group" "eks-nodes" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "${var.prefix}nodes"
  version         = aws_eks_cluster.eks.version
  # release_version = nonsensitive(data.aws_ssm_parameter.eks_ami_release_version.value)
  node_role_arn   = aws_iam_role.eks-node-role.arn
  subnet_ids      = [aws_subnet.eks_worker.id, aws_subnet.eks_worker_1.id, aws_subnet.eks_worker_2.id]
  instance_types = ["m5.2xlarge"]

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  # launch_template {
  #   name = aws_launch_template.hugepages.name
  #   version = 1
  # }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.eks-node-attach-0,
    aws_iam_role_policy_attachment.eks-node-attach-1,
    aws_iam_role_policy_attachment.eks-node-attach-2,
  ]
  tags = {
    Name  = "${var.prefix}nodes"
    owner = var.uk_se_name
  }
}

resource "aws_launch_template" "hugepages" {
  name = "hugepages"

  block_device_mappings {
    device_name = "/dev/sdf"

    ebs {
      volume_type = "standard"
      volume_size = 200
      delete_on_termination = true
    }
  }

  user_data = filebase64("${path.module}/templates/eks-hugepage-user-data.tpl")
}

resource "aws_iam_role" "eks-cluster-role" {
  name = "${var.prefix}cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks-cluster-attach-0" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-cluster-role.name
}

resource "aws_iam_role_policy_attachment" "eks-cluster-attach-1" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks-cluster-role.name
}

resource "aws_iam_role" "eks-node-role" {
  name = "${var.prefix}node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks-node-attach-0" {
  role       = aws_iam_role.eks-node-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks-node-attach-1" {
  role       = aws_iam_role.eks-node-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "eks-node-attach-2" {
  role       = aws_iam_role.eks-node-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

data "aws_ssm_parameter" "eks_ami_release_version" {
  name = "/aws/service/eks/optimized-ami/${aws_eks_cluster.eks.version}/amazon-linux-2/recommended/release_version"
}