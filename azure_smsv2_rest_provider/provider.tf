terraform {
  required_providers {
    volterra = {
      source  = "volterraedge/volterra"
      version = "0.11.40"
    }
    azurerm = {
      version = "3.49.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.9.0"
    }
    restful = {
      source  = "magodo/restful"
      version = ">= 0.16.1"
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


provider "restful" {
  base_url = var.f5xc_api_url
  security = {
    apikey = [
      {
        in    = "header"
        name  = "Authorization"
        value = format("APIToken %s", var.f5xc_api_token)
      },
    ]
  }
}