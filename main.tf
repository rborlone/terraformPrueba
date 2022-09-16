resource "azurerm_resource_group" "example" {
  name     = var.rg_name
  location = var.location
}

resource "azurerm_virtual_network" "example-vnet" {
  name                = "example-vnet"
  resource_group_name = azurerm_resource_group.example.name
  address_space       = var.address_space
  location            = azurerm_resource_group.example.location
}

resource "azurerm_subnet" "example-subnet" {
  name                 = "example-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example-vnet.name
  address_prefixes     = var.address_subnet_space_aks

  delegation {
    name = "delegation"

    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"]
    }
  }
}

resource "azurerm_subnet" "example-subnet-2" {
  name                 = "example-subnet-2"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example-vnet.name
  address_prefixes     = var.address_subnet-space-ingress

  delegation {
    name = "delegation"

    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"]
    }
  }
}

resource "azurerm_virtual_network_peering" "example-peer-1" {
  name                      = "peer1to2"
  resource_group_name       = azurerm_resource_group.example.name
  virtual_network_name      = azurerm_virtual_network.example-vnet.name
  remote_virtual_network_id = var.id-vnet-firewall
}

resource "azurerm_virtual_network_peering" "example-peer-2" {
  name                      = "peer2to1"
  resource_group_name       = var.name-rg-firewall
  virtual_network_name      = var.name-vnet-firewall
  remote_virtual_network_id = azurerm_virtual_network.example-vnet.id
}

resource "azurerm_route_table" "example" {
  name                          = "example-route-table"
  location                      = azurerm_resource_group.example.location
  resource_group_name           = azurerm_resource_group.example.name
  disable_bgp_route_propagation = false

  route {
    name           = "allinternetfw"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = var.ip-internal-firewall
  }

  tags = {
    environment = "Production"
  }
}

resource "azurerm_subnet_route_table_association" "example" {
  subnet_id      = azurerm_subnet.example-subnet.id
  route_table_id = azurerm_route_table.example.id
}