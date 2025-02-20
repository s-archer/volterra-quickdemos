terraform {
  required_providers {

    # f5os = {
    #   source = "F5Networks/f5os"
    #   version = "1.4.1"
    # }

    volterra = {
      source  = "volterraedge/volterra"
      version = "0.11.42"
    }

    # restful = {
    #   source  = "magodo/restful"
    #   version = "0.18.1"
    # }

    null = {
      source = "hashicorp/null"
      version = "3.2.3"
    }

    # local = ">= 2.2.3"
    # null  = ">= 3.1.1"
  }
}



provider "volterra" {
  api_p12_file = var.f5xc_api_p12_file
  url          = var.f5xc_api_url
}

# provider "restful" {
#   alias = "f5os_api"
#   base_url = var.f5os_api_url
#   security = {
#     http = {
#       basic = {
#         username = "admin"
#         password = "Br0ken-Arr0w"
#       }
#     }
#   }
#   client = {
#     tls_insecure_skip_verify = true
#   }
# }

provider "null" {

}

# provider "f5os" {
#   alias = "reseries-1"
#   username = "admin"
#   password = "Br0kenArr0w"
#   host     = "http://172.30.107.18"
#   disable_tls_verify = true
# }
# # Manage F5OS Tenant

# provider "f5os" {
#   alias = "reseries-2"
#   username = "admin"
#   password = "Br0kenArr0w"
#   host     = "http://172.30.107.19"
#   disable_tls_verify = true
# }