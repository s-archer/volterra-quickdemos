terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
    volterra = {
      source = "volterraedge/volterra"
    }
  }
}

provider "volterra" {
  api_p12_file = var.volt_api_p12_file
  url          = var.volt_api_url
}

provider "google" {
  project = var.project_id
  region  = var.gcp_region
}
