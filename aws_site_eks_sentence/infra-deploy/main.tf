terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      # version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.18.1"
    }
    volterra = {
      source  = "volterraedge/volterra"
      version = "0.11.8"
    }
  }
}

provider "aws" {
  region                   = var.region
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "Default"
  default_tags {
    tags = {
      owner = var.uk_se_name
    }
  }
}

provider "kubernetes" {
  host                   = aws_eks_cluster.arch-eks.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.arch-eks.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.arch-eks.name]
    command     = "aws"
  }
}

provider "volterra" {
  api_p12_file = var.volt_api_p12_file
  url          = var.volt_api_url
}

data "http" "myip" {
  url = "https://ifconfig.me"
}