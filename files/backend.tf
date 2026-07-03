terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.78.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "tfstate-backup-rg"
    storage_account_name = "newsta8996"
    container_name       = "tfstate"
    key                  = "aks-cicd.terraform.tfstate"
  }

  required_version = ">= 1.9.0"
}

provider "azurerm" {
  features {}
}
