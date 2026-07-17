data "terraform_remote_state" "eks" {
  backend = "local"
  config = {
    path = "../infra-deploy/terraform.tfstate"
  }
}

provider "helm" {
  kubernetes {
    host                   = data.terraform_remote_state.eks.outputs.cluster-endpoint
    cluster_ca_certificate = base64decode(data.terraform_remote_state.eks.outputs.kubeconfig-certificate-authority-data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", data.terraform_remote_state.eks.outputs.cluster-name]
      command     = "aws"
    }
  }
}