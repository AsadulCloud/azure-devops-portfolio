terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.78.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    } 
  }

  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstateasadul001"
    container_name       = "tfstatecapstone"
    key                  = "dev.terraform.tfstate"
  }

  required_version = ">= 1.9.0"
}

provider "azurerm" {
  features {}
  use_oidc = true
}
