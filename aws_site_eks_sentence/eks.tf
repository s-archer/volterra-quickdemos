resource "aws_eks_cluster" "arch-eks" {
  name     = "arch-eks"
  role_arn = aws_iam_role.eks-cluster-role.arn

  vpc_config {
    subnet_ids = [aws_subnet.eks_control.id, aws_subnet.eks_control_1.id, aws_subnet.eks_control_2.id]
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.arch-eks-cluster-attach-0,
    aws_iam_role_policy_attachment.arch-eks-cluster-attach-1,
  ]
}

resource "aws_eks_node_group" "arch-eks-nodes" {
  cluster_name    = aws_eks_cluster.arch-eks.name
  node_group_name = "arch-eks-nodes"
  version         = aws_eks_cluster.arch-eks.version
  release_version = nonsensitive(data.aws_ssm_parameter.eks_ami_release_version.value)
  node_role_arn   = aws_iam_role.arch-eks-node-role.arn
  subnet_ids      = [aws_subnet.eks_data.id, aws_subnet.eks_data_1.id, aws_subnet.eks_data_2.id]

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.arch-eks-node-attach-0,
    aws_iam_role_policy_attachment.arch-eks-node-attach-1,
    aws_iam_role_policy_attachment.arch-eks-node-attach-2,
  ]
}

resource "aws_iam_role" "eks-cluster-role" {
  name = "arch-eks-cluster-role"
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

resource "aws_iam_role_policy_attachment" "arch-eks-cluster-attach-0" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-cluster-role.name
}

resource "aws_iam_role_policy_attachment" "arch-eks-cluster-attach-1" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks-cluster-role.name
}

resource "aws_iam_role" "arch-eks-node-role" {
  name = "arch-eks-node-role"

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

resource "aws_iam_role_policy_attachment" "arch-eks-node-attach-0" {
  role      = aws_iam_role.arch-eks-node-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "arch-eks-node-attach-1" {
  role      = aws_iam_role.arch-eks-node-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "arch-eks-node-attach-2" {
  role      = aws_iam_role.arch-eks-node-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}


data "aws_ssm_parameter" "eks_ami_release_version" {
  name = "/aws/service/eks/optimized-ami/${aws_eks_cluster.arch-eks.version}/amazon-linux-2/recommended/release_version"
}