
resource "volterra_discovery" "k8s" {
  name      = "${var.prefix}sentence"
  namespace = "system"
  depends_on = [
    azurerm_kubernetes_cluster.aks,
    volterra_tf_params_action.site
  ]

  discovery_k8s {
    access_info {
      // One of the arguments from this list "kubeconfig_url connection_info in_cluster" must be set
      kubeconfig_url {
        clear_secret_info {
          url = format("string:///%s", base64encode(azurerm_kubernetes_cluster.aks.kube_config_raw))
        }
      }

      // One of the arguments from this list "isolated reachable" must be set
      reachable = true
    }

    publish_info {
      // One of the arguments from this list "disable publish publish_fqdns dns_delegation" must be set
      #disable = true
      publish {
        namespace = var.aks_k8s_namespace
      }
    }
  }
  where {
    site {
      network_type = "VIRTUAL_NETWORK_SITE_LOCAL_INSIDE"
      ref {
        name      = volterra_azure_vnet_site.site.name
        namespace = volterra_azure_vnet_site.site.namespace
      }
    }
  }
}