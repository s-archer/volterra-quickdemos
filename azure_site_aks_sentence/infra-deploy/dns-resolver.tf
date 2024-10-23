resource "azurerm_private_dns_resolver" "dr" {
  name                = "arch-dns-resolver"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  virtual_network_id  = azurerm_virtual_network.uksouth.id
}

resource "azurerm_private_dns_resolver_outbound_endpoint" "dns-out" {
  name                    = "arch-dns-endpoint"
  private_dns_resolver_id = azurerm_private_dns_resolver.dr.id
  location                = azurerm_private_dns_resolver.dr.location
  subnet_id               = azurerm_subnet.dns-endpoint.id
  tags = {
    owner = "s.archer@f5.com"
  }
}

resource "azurerm_private_dns_resolver_dns_forwarding_ruleset" "dns-out" {
  name                                       = "arch-dns-out"
  resource_group_name                        = azurerm_resource_group.rg.name
  location                                   = azurerm_resource_group.rg.location
  private_dns_resolver_outbound_endpoint_ids = [azurerm_private_dns_resolver_outbound_endpoint.dns-out.id]
}

resource "azurerm_private_dns_resolver_forwarding_rule" "dns-xc-out" {
  name                      = "arch-dns-xc-out"
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.dns-out.id
  domain_name               = "azure.local."
  enabled                   = true
  target_dns_servers {
    ip_address = data.azurerm_network_interface.master-0-sli.private_ip_address
    port       = 53
  }


}

resource "azurerm_private_dns_resolver_virtual_network_link" "dns-xc-out-link" {
  name                      = "arch-dns-xc-out-link"
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.dns-out.id
  virtual_network_id        = azurerm_virtual_network.uksouth.id
}

data "azurerm_network_interface" "master-0-sli" {
  name                = "master-0-sli"
  resource_group_name = format("%srg-%s", var.prefix, "xc")
  depends_on          = [volterra_tf_params_action.site]
}

# data "azurerm_network_interface" "master-1-sli" {
#   name                = "master-1-sli"
#   resource_group_name = format("%srg-%s", var.prefix, "xc")
#   depends_on          = [volterra_tf_params_action.site]
# }

# data "azurerm_network_interface" "master-2-sli" {
#   name                = "master-2-sli"
#   resource_group_name = format("%srg-%s", var.prefix, "xc")
#   depends_on          = [volterra_tf_params_action.site]
# }