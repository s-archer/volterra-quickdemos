terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      # version = "~> 3.0"
    }
    volterra = {
      source  = "volterraedge/volterra"
      version = "0.11.8"
    }
  }
}

provider "volterra" {
  api_p12_file = var.volt_api_p12_file
  url          = var.volt_api_url
}

provider "aws" {
  region                  = var.region
  shared_credentials_files = ["~/.aws/credentials"]
  profile                 = "Default"
  default_tags {
    tags = {
      owner = var.uk_se_name
    }
  }
}

data "http" "myip" {
  url = "https://ifconfig.me"
}