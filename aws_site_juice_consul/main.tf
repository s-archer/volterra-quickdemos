terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    volterra = {
      source  = "volterraedge/volterra"
      version = "0.11.8"
    }
  }
}

provider "volterra" {
  api_p12_file = "../../creds/f5-emea-ent.console.ves.volterra.io.api-creds.p12"
  url          = "https://f5-emea-ent.console.ves.volterra.io/api"
}

provider "aws" {
  region                  = var.region
  shared_credentials_file = "~/.aws/credentials"
  profile                 = "Default"
}

data "http" "myip" {
  url = "https://ifconfig.me"
}