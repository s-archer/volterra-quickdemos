data "terraform_remote_state" "aks" {
  backend = "local"
  config = {
    path = "../infra-deploy/terraform.tfstate"
  }
}

provider "helm" {
  kubernetes {
    config_path = "../infra-deploy/kube_config.yaml"
  }
}
