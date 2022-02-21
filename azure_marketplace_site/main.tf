terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "2.97.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource random_id id {
  byte_length = 2
}

resource azurerm_resource_group rg {
  name     = format("%s-rg-%s", var.prefix, random_id.id.hex)
  location = var.location
}

resource "azurerm_network_security_group" "vnet_sg" {
  name                = format("%s-sg-%s", var.prefix, random_id.id.hex)
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_virtual_network" "vnet" {
  name                = format("%s-vnet-%s", var.prefix, random_id.id.hex)
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [var.cidr]

  subnet {
    name           = "outside"
    address_prefix = cidrsubnet(var.cidr, 8, 1)
  }

  subnet {
    name           = "inside"
    address_prefix = cidrsubnet(var.cidr, 8, 2)
    security_group = azurerm_network_security_group.vnet_sg.id
  }

  tags = {
    environment = "Demo"
    uk_se       = var.uk_se_name
  }
}

resource "azurerm_network_interface" "outside" {
  name                = "example-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "outside"
    subnet_id                     = azurerm_virtual_network.vnet.subnet.*.id[0]
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "inside" {
  name                = "example-nic"
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
  custom_data    = base64encode(templatefile("./templates/user_data.tpl", {
    site_token         = var.site_token
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