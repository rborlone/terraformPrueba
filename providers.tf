terraform {
  required_version = ">=1.0"

  backend "azurerm" {
      resource_group_name   = "rg-tf-blobstore"
      storage_account_name  = ""
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
}