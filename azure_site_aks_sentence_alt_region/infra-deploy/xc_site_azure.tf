resource "volterra_azure_vnet_site" "site" {
  name      = var.site_name
  namespace = "system"

  azure_region   = var.location
  resource_group = format("%srg-%s", var.prefix, "xc")

  machine_type = "Standard_D3_v2"

  default_blocked_services = true
  logs_streaming_disabled  = true

  ssh_key = trimspace(tls_private_key.demo.public_key_openssh)

  azure_cred {
    name      = var.cloud_cred_name
    namespace = "system"
  }

  ingress_egress_gw {

    azure_certified_hw = "azure-byol-multi-nic-voltmesh"

    no_forward_proxy         = true
    no_global_network        = true
    no_network_policy        = true
    no_outside_static_routes = true

    az_nodes {
      azure_az = "3"

      outside_subnet {
        subnet {
          subnet_name         = azurerm_subnet.outside.name
          vnet_resource_group = true
        }
      }

      inside_subnet {
        subnet {
          subnet_name         = azurerm_subnet.inside.name
          vnet_resource_group = true
        }
      }
    }

    # Uncomment below to create a three-node cluster
    # az_nodes {
    #   azure_az = "2"

    #   outside_subnet {
    #     subnet {
    #       subnet_name         = azurerm_subnet.outside.name
    #       vnet_resource_group = true
    #     }
    #   }

    #   inside_subnet {
    #     subnet {
    #       subnet_name         = azurerm_subnet.inside.name
    #       vnet_resource_group = true
    #     }
    #   }
    # }

    # az_nodes {
    #   azure_az = "1"

    #   outside_subnet {
    #     subnet {
    #       subnet_name         = azurerm_subnet.outside.name
    #       vnet_resource_group = true
    #     }
    #   }

    #   inside_subnet {
    #     subnet {
    #       subnet_name         = azurerm_subnet.inside.name
    #       vnet_resource_group = true
    #     }
    #   }
    # }
  }

  vnet {

    existing_vnet {
      vnet_name      = azurerm_virtual_network.uksouth.name
      resource_group = azurerm_resource_group.rg.name

    }
  }
  // One of the arguments from this list "nodes_per_az total_nodes no_worker_nodes" must be set
  no_worker_nodes = true
}

resource "null_resource" "wait-for-site" {
  triggers = {
    depends = volterra_azure_vnet_site.site.id
  }
}

resource "volterra_api_credential" "api" {
  name                = format("%s-%s-api-token-%s", var.uk_se_name, var.base, random_id.id.hex)
  api_credential_type = "API_TOKEN"

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOF
      #!/bin/bash
      NAME=$(curl --location --request GET 'https://f5-emea-ent.console.ves.volterra.io/api/web/namespaces/system/api_credentials' \
        --header 'Authorization: APIToken ${self.data}'| jq 'first(.items[] | select (.name | contains("${self.name}")) | .name)') 
      curl --location --request POST 'https://f5-emea-ent.console.ves.volterra.io/api/web/namespaces/system/revoke/api_credentials' \
        --header 'Authorization: APIToken ${self.data}' \
        --header 'Content-Type: application/json' \
        -d "$(jq -n --arg n "$NAME" '{"name": $n, "namespace": "system" }')"
    EOF
  }
}

resource "volterra_tf_params_action" "site" {
  depends_on      = [null_resource.wait-for-site]
  site_name       = var.site_name
  site_kind       = "azure_vnet_site"
  action          = "apply"
  wait_for_action = true

  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      x=1;
      while [ $x -le 60 ]; 
        do STATE=$(curl -s --location --request GET '${var.volt_api_url}/config/namespaces/system/azure_vnet_sites/${var.site_name}' --header 'Authorization: APIToken ${volterra_api_credential.api.data}'| jq .spec.site_state); 
        if ( echo $STATE | grep "ONLINE" ); 
          then break; 
        fi; 
        sleep 30; 
        x=$(( $x + 1 )); 
      done
    EOF
  }
}