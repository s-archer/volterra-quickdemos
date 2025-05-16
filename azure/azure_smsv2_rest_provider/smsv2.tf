resource "restful_resource" "token" {
  count       = var.f5xc_sms_node_count
  depends_on  = [restful_resource.site]
  path        = format(var.f5xc_token_base_uri, var.f5xc_namespace)
  read_path   = format(var.f5xc_token_read_uri, var.f5xc_namespace, format("%s-node-%s", local.f5xc_sms_name, count.index))
  delete_path = format(var.f5xc_token_delete_uri, var.f5xc_namespace, format("%s-node-%s", local.f5xc_sms_name, count.index))
  header = {
    Content-Type = "application/json"
  }
  body = {
    metadata = {
      name      = format("%s-node-%s", local.f5xc_sms_name, count.index)
      namespace = var.f5xc_namespace
    }
    spec = {
      type      = "JWT"
      site_name = format("%s-node-%s", local.f5xc_sms_name, count.index)
    }
  }
}

resource "restful_resource" "site" {
  count       = var.f5xc_sms_node_count
  path        = format(var.f5xc_sms_base_uri, var.f5xc_namespace)
  read_path   = format(var.f5xc_sms_read_uri, var.f5xc_namespace, format("%s-node-%s", local.f5xc_sms_name, count.index))
  delete_path = format(var.f5xc_sms_delete_uri, var.f5xc_namespace, format("%s-node-%s", local.f5xc_sms_name, count.index))
  header = {
    Content-Type = "application/json"
  }
  body = {
    metadata = {
      name        = format("%s-node-%s", local.f5xc_sms_name, count.index)
      # labels      = var.f5xc_sms_labels
      labels = {
        (volterra_known_label_key.key.key) = (volterra_known_label.label.value)
        "ves.io/provider" = "ves-io-AZURE"
      }
      disable     = var.f5xc_sms_disable
      namespace   = var.f5xc_namespace
      annotations = var.f5xc_sms_annotations
      description = var.f5xc_sms_description
    }
    spec = merge({
      (var.f5xc_sms_provider_name) = {
        not_managed = {}
      }
      software_settings            = local.software_settings
      performance_enhancement_mode = local.performance_enhancement_mode
      re_select = {
        geo_proximity = {}
      }
      tunnel_type             = var.f5xc_sms_tunnel_type
      no_forward_proxy        = var.f5xc_sms_no_forward_proxy ? {} : null
      no_network_policy       = var.f5xc_sms_no_network_policy ? {} : null
      # active_enhanced_firewall_policies = {
      #   enhanced_firewall_policies = {
      #     name      = "arch-vsite-fw-policy"
      #     namespace = "system"
      #   }
      # }
      block_all_services      = var.f5xc_sms_block_all_services ? {} : null
      tunnel_dead_timeout     = var.f5xc_sms_tunnel_dead_timeout
      logs_streaming_disabled = var.f5xc_sms_logs_streaming_disabled ? {} : null
      enable_ha               = var.f5xc_sms_master_nodes_count == 1 ? null : {}
      offline_survivability_mode = {
        enable_offline_survivability_mode = var.f5xc_sms_enable_offline_survivability_mode ? {} : null
      }
      },
      local.spec
    )
  }
}


resource "azurerm_virtual_machine" "f5xc-nodes" {
  count                        = var.f5xc_sms_node_count
  depends_on                   = [azurerm_network_interface_security_group_association.outside_security, azurerm_network_interface_security_group_association.inside_security]
  name                         = "${var.prefix}-node-${count.index}"
  location                     = var.location
  zones                        = [var.azs_short[count.index]]
  resource_group_name          = azurerm_resource_group.rg.name
  primary_network_interface_id = azurerm_network_interface.outside_nic[count.index].id
  network_interface_ids        = [azurerm_network_interface.outside_nic[count.index].id, azurerm_network_interface.inside_nic[count.index].id]
  vm_size                      = var.f5xc_sms_instance_type

  # Uncomment these lines to delete the disks automatically when deleting the VM
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true
  identity {
    type = "SystemAssigned"
  }

  plan {
    name      = "f5xccebyol"
    publisher = "f5-networks"
    product   = "f5xc_customer_edge"
  }

  storage_image_reference {
    publisher = "f5-networks"
    offer     = "f5xc_customer_edge"
    sku       = "f5xccebyol"
    version   = "2024.44.2"
  }

  storage_os_disk {
    name              = "${var.prefix}-node-${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = var.f5xc_sms_storage_account_type
  }

  os_profile {
    computer_name  = "${var.prefix}-node-${count.index}"
    admin_username = "volterra-admin"
    admin_password = random_string.password.result
    custom_data = base64encode(templatefile("${path.module}/templates/user-data.tpl", {
      cluster_name = format("%s-node-%s", local.f5xc_sms_name, count.index),
      token        = restful_resource.token[count.index].output.spec.content
    }))
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    Name   = "${var.prefix}-node-[count.index]"
    source = "terraform"
    owner       = var.owner
  }
}


resource "azurerm_network_interface" "outside_nic" {
  count               = var.f5xc_sms_node_count
  name                = "${var.prefix}-outside-nic-${count.index}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "${var.prefix}-outside-ip-${count.index}"
    subnet_id                     = azurerm_subnet.outside.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.outside_public_ip[count.index].id
  }
  tags = {
    Name   = "${var.prefix}-outside-nic-${count.index}"
    source = "terraform"
  }
}


resource "azurerm_public_ip" "outside_public_ip" {
  count               = var.f5xc_sms_node_count
  name                = "${var.prefix}-outside-pip-${count.index}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  domain_name_label   = format("%s-outside-%s", var.prefix, count.index)
  allocation_method   = "Static"
  sku                 = "Standard"
  # zones               = var.availabilityZones
  tags = {
    Name   = "${var.prefix}-outside-pip-${count.index}"
    source = "terraform"
  }
}


resource "azurerm_network_interface" "inside_nic" {
  count                = var.f5xc_sms_node_count
  name                 = "${var.prefix}-inside-nic-${count.index}"
  location             = var.location
  resource_group_name  = azurerm_resource_group.rg.name
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "${var.prefix}-inside-ip-${count.index}"
    subnet_id                     = azurerm_subnet.inside.id
    private_ip_address_allocation = "Dynamic"
    # public_ip_address_id          = azurerm_public_ip.inside_public_ip[count.index].id
  }
  tags = {
    Name   = "${var.prefix}-inside-nic-${count.index}"
    source = "terraform"
  }
}


resource "azurerm_network_interface_security_group_association" "outside_security" {
  count                     = var.f5xc_sms_node_count
  network_interface_id      = azurerm_network_interface.outside_nic[count.index].id
  network_security_group_id = module.outside-network-security-group.network_security_group_id
}


resource "azurerm_network_interface_security_group_association" "inside_security" {
  count                     = var.f5xc_sms_node_count
  network_interface_id      = azurerm_network_interface.inside_nic[count.index].id
  network_security_group_id = module.inside-network-security-group-public.network_security_group_id
}