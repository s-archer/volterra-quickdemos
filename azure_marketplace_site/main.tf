terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.97.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "random_id" "id" {
  byte_length = 2
}

resource "azurerm_resource_group" "rg" {
  name     = format("%s-rg-%s", var.prefix, random_id.id.hex)
  location = var.location
}

resource "azurerm_network_security_group" "vnet_sg" {
  name                = format("%s-sg-%s", var.prefix, random_id.id.hex)
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                         = "allow F5XC documented domains out"
    priority                     = 100
    direction                    = "Outbound"
    access                       = "Allow"
    protocol                     = "Tcp"
    source_port_range            = "*"
    destination_port_ranges      = ["80", "443"]
    source_address_prefix        = "*"
    destination_address_prefixes = local.cidrs
  }

  security_rule {
    name                         = "allow F5XC documented HTTP and HTTS out"
    priority                     = 101
    direction                    = "Outbound"
    access                       = "Allow"
    protocol                     = "Tcp"
    source_port_range            = "*"
    destination_port_ranges      = ["80", "443"]
    source_address_prefix        = "*"
    destination_address_prefixes = ["5.182.213.0/25", "5.182.212.0/25", "5.182.213.128/25", "5.182.214.0/25", "20.150.0.0/16", "34.0.0.0/8", "44.196.0.0/16", "51.140.0.0/15", "52.0.0.0/8", "54.0.0.0/8", "64.0.0.0/8", "74.0.0.0/8", "81.21.0.0/16", "83.151.0.0/16", "84.54.60.0/25", "85.199.0.0/16", "90.155.0.0/16", "104.18.0.0/16", "108.0.0.0/7", "129.250.0.0/16", "162.159.0.0/16", "172.0.0.0/6", "185.0.0.0/16", "192.33.0.0/16", "208.67.0.0/16", "209.51.0.0/16", "216.0.0.0/6"]
  }

  security_rule {
    name                         = "allow F5XC documented IPSEC out"
    priority                     = 102
    direction                    = "Outbound"
    access                       = "Allow"
    protocol                     = "Udp"
    source_port_range            = "*"
    destination_port_range       = "4500"
    source_address_prefix        = "*"
    destination_address_prefixes = ["5.182.213.0/25", "5.182.212.0/25", "5.182.213.128/25", "5.182.214.0/25", "84.54.60.0/25", "185.56.154.0/25"]
  }

  security_rule {
    name                       = "deny any outbound"
    priority                   = 103
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = format("%s-vnet-%s", var.prefix, random_id.id.hex)
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [var.cidr]

  subnet {
    name           = "outside"
    address_prefix = cidrsubnet(var.cidr, 8, 1)
    security_group = azurerm_network_security_group.vnet_sg.id
  }

  subnet {
    name           = "inside"
    address_prefix = cidrsubnet(var.cidr, 8, 2)
  }

  tags = {
    environment = "Demo"
    uk_se       = var.uk_se_name
  }
}

resource "azurerm_network_interface" "outside" {
  name                = "outside-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "outside"
    subnet_id                     = azurerm_virtual_network.vnet.subnet.*.id[0]
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "inside" {
  name                = "inside-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "inside"
    subnet_id                     = azurerm_virtual_network.vnet.subnet.*.id[1]
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "f5_xc_master" {
  name                = "f5xcmaster"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = var.f5_xc_instance_type
  admin_username      = "adminuser"
  custom_data = base64encode(templatefile("./templates/user_data.tpl", {
    site_token = var.site_token
  }))
  network_interface_ids = [
    azurerm_network_interface.outside.id,
    azurerm_network_interface.inside.id
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "volterraedgeservices"
    offer     = "volterra-node"
    sku       = "volterra-node"
    version   = "latest"
  }

  plan {
    name      = "volterra-node"
    product   = "volterra-node"
    publisher = "volterraedgeservices"
  }

  tags = {
    environment = "Demo"
    uk_se       = var.uk_se_name
  }
}