terraform {
  required_providers {
    volterra = {
      source  = "volterraedge/volterra"
      version = "0.11.24"
    }
    azurerm = {
      version = "3.49.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.9.0"
    }
  }
}

provider "volterra" {
  api_p12_file = var.volt_api_p12_file
  url          = var.volt_api_url
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  client_secret   = var.client_secret
  client_id       = var.client_id
  tenant_id       = var.tenant_id
}

resource "random_id" "id" {
  byte_length = 2
}