resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.prefix}k8s"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "${var.prefix}k8s"


  default_node_pool {
    name = "default"
    # Next line identifies the worker subnet id.
    vnet_subnet_id = azurerm_subnet.workers.id
    node_count     = 1
    vm_size        = "Standard_DC4s_v2"
    zones          = ["1"]
  }

  network_profile {
    # network_plugin     = "kubenet"
    network_plugin = "azure"
    service_cidr   = "10.0.201.0/24"
    # pod_cidr           = "10.0.200.0/24"
    dns_service_ip = "10.0.201.53"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = "Demo"
    owner       = var.uk_se_name
  }
}

resource "local_file" "kube_config" {
  content  = azurerm_kubernetes_cluster.aks.kube_config_raw
  filename = "kube_config.yaml"
}