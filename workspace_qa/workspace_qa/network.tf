resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-VNet"
  address_space       = var.vnet_range
  dns_servers         = var.dns_servers
  location            = azurerm_resource_group.rg_vdi.location
  resource_group_name = azurerm_resource_group.rg_vdi.name
  #depends_on          = [vazurerm_resource_group.rg_vdi.name]
}

resource "azurerm_subnet" "subnet" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.rg_vdi.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnet_range
 # depends_on           = [vazurerm_resource_group.rg_vdi.name]
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}-NSG"
  location            = azurerm_resource_group.rg_vdi.location
  resource_group_name = azurerm_resource_group.rg_vdi.name
  security_rule {
    name                       = "HTTPS"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  #depends_on = [azurerm_resource_group.rg_vdi.name]
}

resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

data "azurerm_virtual_network" "ad_vnet_data" {
  name                = var.ad_vnet
  resource_group_name = var.ad_rg
}

resource "azurerm_virtual_network_peering" "peer1" {
  name                      = "peer_avdspoke_ad"
  resource_group_name       = azurerm_resource_group.rg_vdi.name
  virtual_network_name      = azurerm_virtual_network.vnet.name
  remote_virtual_network_id = data.azurerm_virtual_network.ad_vnet_data.id
}
resource "azurerm_virtual_network_peering" "peer2" {
  name                      = "peer_ad_avdspoke"
  resource_group_name       = var.ad_rg
  virtual_network_name      = var.ad_vnet
  remote_virtual_network_id = azurerm_virtual_network.vnet.id
}

