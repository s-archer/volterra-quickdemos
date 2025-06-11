data "terraform_remote_state" "aks" {
  backend = "local"
  config = {
    path = "../infra-deploy/terraform.tfstate"
  }
}

terraform {
  required_providers {
    volterra = {
      source  = "volterraedge/volterra"
      version = "0.11.43"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.37.1"
    }
    local = ">= 2.2.3"
  }
}

provider "volterra" {
  api_p12_file = var.volt_api_p12_file
  url          = var.volt_api_url
}

provider "kubernetes" {
  config_path = "../infra-deploy/kube_config.yaml"
}