terraform {
  required_providers {
    volterra = {
      source  = "volterraedge/volterra"
      version = "0.11.24"
    }
  }
}

provider "helm" {
  kubernetes {
    config_path = "${path.module}/kubeconfig.yaml"
  }
}

provider "volterra" {
  api_p12_file = var.xc_api_p12_file
  url          = var.xc_api_url
}