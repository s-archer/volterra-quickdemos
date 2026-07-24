resource "random_password" "tailscale_subnet_router_ipsec_psk" {
  length  = 32
  special = false
}

resource "azurerm_public_ip" "tailscale_subnet_router" {
  name                = "${var.prefix}-tailscale-subnet-router-public"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "${azurerm_resource_group.rg.name}-tailscale-router"

  tags = {
    Name   = "tailscale-subnet-router"
    Source = "terraform"
    Owner  = var.uk_se_name
  }
}

resource "azurerm_network_interface" "tailscale_subnet_router" {
  name                  = "${var.prefix}-tailscale-subnet-router-nic"
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg.name
  ip_forwarding_enabled = true

  ip_configuration {
    name                          = "${var.prefix}-tailscale-subnet-router-ip"
    subnet_id                     = azurerm_subnet.workers.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.tailscale_subnet_router.id
  }

  tags = {
    Name   = "tailscale-subnet-router"
    Source = "terraform"
    Owner  = var.uk_se_name
  }
}

resource "azurerm_linux_virtual_machine" "tailscale_subnet_router" {
  name                = "${var.prefix}-tailscale-subnet-router-vm"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_DS1_v2"

  vm_agent_platform_updates_enabled = true

  admin_username                  = "azureuser"
  admin_password                  = random_string.password.result
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.tailscale_subnet_router.id
  ]

  custom_data = base64encode(templatefile("${path.module}/templates/tailscale-subnet-router.tpl", {
    azure_region     = var.location
    local_private_ip = azurerm_network_interface.tailscale_subnet_router.private_ip_address
    # remote_private_ip    = azurerm_network_interface.inside_nic[0].private_ip_address
    remote_private_ip    = azurerm_network_interface.outside_nic[0].private_ip_address
    strongswan_ipsec_psk = random_password.tailscale_subnet_router_ipsec_psk.result
    tailscale_auth_key   = var.tailscale_auth_key
    tailscale_tag        = var.tailscale_tag
  }))

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  os_disk {
    name                 = "${var.prefix}-tailscale-subnet-router-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  tags = {
    Name   = "tailscale-subnet-router"
    Source = "terraform"
    Owner  = var.uk_se_name
  }

  lifecycle {
    ignore_changes = [
      custom_data
    ]
  }
}

resource "azurerm_managed_disk" "tailscale_subnet_router_data" {
  name                 = "${var.prefix}-tailscale-subnet-router-datadisk"
  location             = var.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 10

  tags = {
    Name   = "tailscale-subnet-router"
    Source = "terraform"
    Owner  = var.uk_se_name
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "tailscale_subnet_router_data" {
  managed_disk_id    = azurerm_managed_disk.tailscale_subnet_router_data.id
  virtual_machine_id = azurerm_linux_virtual_machine.tailscale_subnet_router.id
  lun                = 0
  caching            = "ReadWrite"
}
