terraform {
  required_providers {
    volterra = {
      source  = "volterraedge/volterra"
      version = "0.11.42"
    }
    azurerm = {
      version = "3.49.0"
    }

    local = ">= 2.2.3"
    null  = ">= 3.1.1"
  }
}

provider "volterra" {
  api_p12_file = var.f5xc_api_p12_file
  url          = var.f5xc_api_url
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  client_secret   = var.client_secret
  client_id       = var.client_id
  tenant_id       = var.tenant_id
}