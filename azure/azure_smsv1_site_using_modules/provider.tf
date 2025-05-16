terraform {
  required_version = ">= 1.7.0"

  required_providers {
    volterra = {
      source  = "volterraedge/volterra"
      version = "= 0.11.38"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.25.0"
    }
    restful = {
      source  = "magodo/restful"
      version = ">= 0.16.1"
    }
    local = ">= 2.2.3"
    null  = ">= 3.1.1"
  }
}

provider "restful" {
  base_url      = var.f5xc_api_url
  update_method = "PUT"
  create_method = "POST"
  delete_method = "DELETE"

  client = {
    retry = {
      status_codes = [500, 502, 503, 504]
      count           = 3
      wait_in_sec     = 1
      max_wait_in_sec = 120
    }
  }

  security = {
    apikey = [
      {
        in   = "header"
        name = "Authorization"
        value = format("APIToken %s", var.f5xc_api_token)
      }
    ]
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

