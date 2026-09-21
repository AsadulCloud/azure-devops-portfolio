variable "client_secret" {
}

# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=5.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}

  client_id       = "6b9a9f78-118c-4fc7-8852-b198db66050b"
  client_secret   = var.client_secret
  tenant_id       = "2f556108-1a64-4113-a98f-28265fc0624d"
  subscription_id = "2f556108-1a64-4113-a98f-28265fc0624d"
}
