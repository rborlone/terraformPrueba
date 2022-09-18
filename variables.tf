variable "location" {
  default = "eastus2"
}

variable "rg_name" {
  default = "rg-tf-test"
}

variable "address_space"{
  default = ["172.21.0.0/16"]
}

variable "address_subnet_space_aks"{
  default = ["172.21.1.0/24"]
}

variable "address_subnet-space-ingress"{
  default = ["172.21.2.0/24"]
}

variable "ip_internal_appgateway"{
  default = "172.21.2.4"
}

variable "name-rg-firewall"{
  default = "rg-AccesoRedNegocios"
}

variable "ip-internal-firewall"{
  default = "172.18.0.4"
}

variable "id-vnet-firewall"{
  default = "/subscriptions/eec1fafa-da18-4aa2-8abf-858f269b9331/resourceGroups/rg-AccesoRedNegocios/providers/Microsoft.Network/virtualNetworks/vnet-firewall"
}

variable "name-vnet-firewall"{
  default="vnet-firewall"
}
