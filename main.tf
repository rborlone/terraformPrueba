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
