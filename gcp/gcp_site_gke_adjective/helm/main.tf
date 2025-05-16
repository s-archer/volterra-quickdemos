data "terraform_remote_state" "gke" {
  backend = "local"
  config = {
    path = "../infra-deploy/terraform.tfstate"
  }
}

provider "helm" {
  kubernetes {
    config_path = "../infra-deploy/kubeconfig.yaml"
  }
}