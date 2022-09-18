locals {
  backend_address_pool_name             = "${azurerm_virtual_network.example-vnet.name}-beap"
  frontend_port_name                    = "${azurerm_virtual_network.example-vnet.name}-feport"
  frontend_ip_configuration_name        = "${azurerm_virtual_network.example-vnet.name}-feip"
  http_setting_name                     = "${azurerm_virtual_network.example-vnet.name}-be-htst"
  listener_name                         = "${azurerm_virtual_network.example-vnet.name}-httplstn"
  request_routing_rule_name             = "${azurerm_virtual_network.example-vnet.name}-rqrt"
  redirect_configuration_name           = "${azurerm_virtual_network.example-vnet.name}-rdrcfg"
}

resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = var.location
}

# User Assigned Idntities
resource "azurerm_user_assigned_identity" "testIdentity" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  name = "identity1"
}

resource "azurerm_virtual_network" "example-vnet" {
  name                = "example-vnet"
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = var.address_space
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_subnet" "subnet-aks" {
  name                 = "subnet-aks"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.example-vnet.name
  address_prefixes     = var.address_subnet_space_aks
}

resource "azurerm_subnet" "subnet-ingress" {
  name                 = "subnet-ingress"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.example-vnet.name
  address_prefixes     = var.address_subnet-space-ingress
}

resource "azurerm_virtual_network_peering" "example-peer-1" {
  name                      = "peer1to2"
  resource_group_name       = azurerm_resource_group.rg.name
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
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  disable_bgp_route_propagation = false

  route {
    name           = "allinternetfw"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = var.ip-internal-firewall
  }
}

resource "azurerm_subnet_route_table_association" "urtassociateaks" {
  subnet_id      = azurerm_subnet.subnet-aks.id
  route_table_id = azurerm_route_table.example.id
}

# resource "azurerm_subnet_route_table_association" "urtassociateingress" {
#   subnet_id      = azurerm_subnet.subnet-ingress.id
#   route_table_id = azurerm_route_table.example.id
# }

# Public Ip
resource "azurerm_public_ip" "appgatewaypublicip" {
  name                         = "publicIp1"
  location                     = azurerm_resource_group.rg.location
  resource_group_name          = azurerm_resource_group.rg.name
  allocation_method            = "Static"
  sku                          = "Standard"
}

resource "azurerm_application_gateway" "network" {
  name                = "example-appgateway"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "appGatewayIpConfig"
    subnet_id = azurerm_subnet.subnet-ingress.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_port {
    name = "httpsPort"
    port = 443
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.appgatewaypublicip.id
  }

  frontend_ip_configuration {
    name                 = "${local.frontend_ip_configuration_name}-private"
    subnet_id = "${azurerm_subnet.subnet-ingress.id}"
    private_ip_address_allocation = "Static"
    private_ip_address = var.ip_internal_appgateway
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 1
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
    priority                   = 100
  }

  depends_on = [
    azurerm_virtual_network.example-vnet,
    azurerm_public_ip.appgatewaypublicip,
  ]
}

resource "azurerm_role_assignment" "ra1" {
  scope                = data.azurerm_subnet.kubesubnet.id
  role_definition_name = "Network Contributor"
  principal_id         = var.aks_service_principal_object_id

  depends_on = [azurerm_virtual_network.test]
}

resource "azurerm_role_assignment" "ra2" {
  scope                = azurerm_user_assigned_identity.testIdentity.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = var.aks_service_principal_object_id
  depends_on           = [azurerm_user_assigned_identity.testIdentity]
}

resource "azurerm_role_assignment" "ra3" {
  scope                = azurerm_application_gateway.network.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.testIdentity.principal_id
  depends_on = [
    azurerm_user_assigned_identity.testIdentity,
    azurerm_application_gateway.network,
  ]
}

resource "azurerm_role_assignment" "ra4" {
  scope                = data.azurerm_resource_group.rg.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.testIdentity.principal_id
  depends_on = [
    azurerm_user_assigned_identity.testIdentity,
    azurerm_application_gateway.network,
  ]
}