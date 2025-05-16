resource "volterra_token" "smsv1" {
  name      = local.f5xc_sms_name
  namespace = "system"
  type = 0
}

resource "volterra_securemesh_site" "example" {
  count                    = var.f5xc_sms_node_count
  name                     = format("%s-node-%s", local.f5xc_sms_name, count.index)
  namespace                = "system"
  default_blocked_services = true
  no_bond_devices          = true
  logs_streaming_disabled  = true
  labels = {
    (volterra_known_label_key.key.key) = (volterra_known_label.label.value)
    "ves.io/provider"                  = "ves-io-AZURE"
  }
  master_node_configuration {
    name      = format("%s-node-%s", local.f5xc_sms_name, count.index)
    public_ip = azurerm_public_ip.outside_public_ip[count.index].ip_address
  }

  // One of the arguments from this list "custom_network_config default_network_config" must be set

  default_network_config = true
  volterra_certified_hw  = "azure-byol-multi-nic-voltmesh"
}


resource "azurerm_linux_virtual_machine" "f5_xc_master" {
  count               = var.f5xc_sms_node_count
  name                = format("%s-node-%s", local.f5xc_sms_name, count.index)
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = var.f5_xc_instance_type
  admin_username      = "adminuser"
  custom_data = base64encode(templatefile("./templates/user_data.tpl", {
    site_token   = volterra_token.smsv1.id
    cluster_name = format("%s-node-%s", local.f5xc_sms_name, count.index)
  }))
  network_interface_ids = [
    azurerm_network_interface.outside[count.index].id,
    azurerm_network_interface.inside[count.index].id
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb = 100
  }

  source_image_reference {
    publisher = "volterraedgeservices"
    offer     = "entcloud_voltmesh_voltstack_node"
    sku       = "freeplan_entcloud_voltmesh_voltstack_node_multinic"
    version   = "latest"
  }

  plan {
    name      = "freeplan_entcloud_voltmesh_voltstack_node_multinic"
    product   = "entcloud_voltmesh_voltstack_node"
    publisher = "volterraedgeservices"
  }

  tags = {
    environment = "Demo"
    uk_se       = var.uk_se_name
  }
}



# resource "azurerm_virtual_machine" "f5xc-nodes" {
#   count                        = var.f5xc_sms_node_count
#   depends_on                   = [azurerm_network_interface_security_group_association.outside_security, azurerm_network_interface_security_group_association.inside_security]
#   name                         = "${var.prefix}-node-${count.index}"
#   location                     = var.location
#   zones                        = [var.azs_short[count.index]]
#   resource_group_name          = azurerm_resource_group.rg.name
#   primary_network_interface_id = azurerm_network_interface.outside[count.index].id
#   network_interface_ids        = [azurerm_network_interface.outside[count.index].id, azurerm_network_interface.inside[count.index].id] 
#   vm_size                      = var.f5xc_sms_instance_type

#   # Uncomment these lines to delete the disks automatically when deleting the VM
#   delete_os_disk_on_termination    = true
#   delete_data_disks_on_termination = true
#   identity {
#     type = "SystemAssigned"
#   }

#   storage_image_reference {
#     publisher = "volterraedgeservices"
#     offer     = "volterra-node"
#     sku       = "volterra-node"
#     version   = "latest"
#   }

#   plan {
#     name      = "volterra-node"
#     product   = "volterra-node"
#     publisher = "volterraedgeservices"
#   }

#   storage_os_disk {
#     name              = "${var.prefix}-node-${count.index}"
#     caching           = "ReadWrite"
#     create_option     = "FromImage"
#     managed_disk_type = var.f5xc_sms_storage_account_type
#   }

#   os_profile {
#     computer_name  = "${var.prefix}-node-${count.index}"
#     admin_username = "volterra-admin"
#     admin_password = random_string.password.result
#     custom_data = base64encode(templatefile("${path.module}/templates/user-data.tpl", {
#       cluster_name = format("%s-node-%s", local.f5xc_sms_name, count.index),
#       # token        = restful_resource.token[count.index].output.spec.content
#       token = volterra_token.smsv2-token[count.index].id
#     }))
#   }

#   os_profile_linux_config {
#     disable_password_authentication = false
#   }

#   tags = {
#     Name   = "${var.prefix}-node-[count.index]"
#     source = "terraform"
#     owner  = var.owner
#   }
# }

resource "azurerm_network_interface" "outside" {
  count                         = var.f5xc_sms_node_count
  name                          = "${var.prefix}-outside-nic-${count.index}"
  location                      = var.location
  resource_group_name           = azurerm_resource_group.rg.name
  enable_accelerated_networking = true

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

resource "azurerm_network_interface" "inside" {
  count                         = var.f5xc_sms_node_count
  name                          = "${var.prefix}-inside-nic-${count.index}"
  location                      = var.location
  resource_group_name           = azurerm_resource_group.rg.name
  enable_ip_forwarding          = true
  enable_accelerated_networking = true

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
  network_interface_id      = azurerm_network_interface.outside[count.index].id
  network_security_group_id = module.outside-network-security-group.network_security_group_id
}

resource "azurerm_network_interface_security_group_association" "inside_security" {
  count                     = var.f5xc_sms_node_count
  network_interface_id      = azurerm_network_interface.inside[count.index].id
  network_security_group_id = module.inside-network-security-group-public.network_security_group_id
}

resource "volterra_known_label_key" "key" {
  key         = local.f5xc_sms_name
  namespace   = "shared"
  description = "Used to define lables for Virtual Sites "
}

resource "volterra_known_label" "label" {
  key       = volterra_known_label_key.key.key
  namespace = "shared"
  value     = local.f5xc_sms_name
}

resource "volterra_virtual_site" "ce" {
  name      = local.f5xc_sms_name
  namespace = "shared"

  site_selector {
    expressions = [format("%s = %s", volterra_known_label_key.key.key, volterra_known_label.label.value)]
  }

  site_type = "CUSTOMER_EDGE"
}