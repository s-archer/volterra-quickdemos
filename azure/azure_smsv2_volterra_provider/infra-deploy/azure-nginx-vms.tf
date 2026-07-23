variable "vm_count" {
  type    = number
  default = 2
}

resource "azurerm_public_ip" "nginx" {
  count               = var.vm_count
  name                = "${var.prefix}-public-${count.index + 1}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "${azurerm_resource_group.rg.name}-${count.index + 1}"

  tags = {
    Name   = "nginx-vm-${count.index + 1}"
    Source = "terraform"
    Owner  = var.uk_se_name
  }
}

resource "azurerm_network_interface" "nginx" {
  count               = var.vm_count
  name                = "${var.prefix}-nic-${count.index + 1}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "${var.prefix}-outside-ip-${count.index}"
    subnet_id                     = azurerm_subnet.workers.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.nginx[count.index].id
  }

  tags = {
    Name   = "nginx-vm-${count.index + 1}"
    Source = "terraform"
    Owner  = var.uk_se_name
  }
}

resource "azurerm_network_security_group" "nginx_vms" {
  name                = "${var.prefix}-nginx_vms-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    Name   = "nginx_vms"
    Source = "terraform"
    Owner  = var.uk_se_name
  }
}

resource "azurerm_network_security_rule" "nginx_vms_allow_ssh" {
  name                        = "Allow_ssh"
  priority                    = 201
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  destination_address_prefix  = "*"
  source_address_prefixes     = ["${data.http.myip.response_body}/32"]
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nginx_vms.name
}

resource "azurerm_network_security_rule" "nginx_vms_allow_all_egress" {
  name                        = "Allow_all_egress"
  priority                    = 200
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nginx_vms.name
}

resource "azurerm_network_interface_security_group_association" "nginx_vms" {
  count                     = var.vm_count
  network_interface_id      = azurerm_network_interface.nginx[count.index].id
  network_security_group_id = azurerm_network_security_group.nginx_vms.id
}

resource "azurerm_linux_virtual_machine" "nginx" {
  count               = var.vm_count
  name                = "${var.prefix}-vm-${count.index + 1}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_DS1_v2"

  vm_agent_platform_updates_enabled = true

  admin_username                  = "azureuser"
  admin_password                  = random_string.password.result
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.nginx[count.index].id
  ]

  custom_data = base64encode(templatefile("${path.module}/templates/nginx.tpl", {
    azure_region       = var.location
    server_number      = count.index + 1
    tailscale_auth_key = var.tailscale_auth_key
    tailscale_hostname = "${var.prefix}-nginx-${count.index + 1}"
  }))

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  os_disk {
    name                 = "${var.prefix}-osdisk-${count.index + 1}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  tags = {
    Name   = "nginx-vm-${count.index + 1}"
    Source = "terraform"
    Owner  = var.uk_se_name
  }
}

resource "azurerm_managed_disk" "nginx_data" {
  count                = var.vm_count
  name                 = "${var.prefix}-datadisk-${count.index + 1}"
  location             = var.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 10
}

resource "azurerm_virtual_machine_data_disk_attachment" "nginx_data" {
  count              = var.vm_count
  managed_disk_id    = azurerm_managed_disk.nginx_data[count.index].id
  virtual_machine_id = azurerm_linux_virtual_machine.nginx[count.index].id
  lun                = 0
  caching            = "ReadWrite"
}
