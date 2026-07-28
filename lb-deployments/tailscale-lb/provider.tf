terraform {
  required_providers {
    volterra = {
      source  = "volterraedge/volterra"
      version = "0.11.49"
    }
    tailscale = {
      source  = "tailscale/tailscale"
      version = "0.29.2"
    }
  }
}

provider "volterra" {
  api_p12_file = var.f5xc_api_p12_file
  url          = var.f5xc_api_url
}

provider "tailscale" {
  tailnet = var.tailscale_tailnet
}
