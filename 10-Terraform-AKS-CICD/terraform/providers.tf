terraform {
    required_providers {
        azurerm = {
            source  = "hashicorp/azurerm"
            version = "~> 3.100"
        }
    }

    required_version = ">= 1.5.0"

    # Remote state - keep your terraform state file secure and accessible to your team
    # Instead of storing the state file locally, we can store it in a remote backend like Azure Storage Account, AWS S3, or Terraform Cloud. This allows multiple team members to work on the same infrastructure without conflicts.
    # Create this storage account BEFORE running terraform init (See the README for instructions)
    backend "azurerm" {
        resource_group_name  = "tfstate-rg"
        storage_account_name = "tfstateasadul001"
        container_name       = "tfstate"
        key                  = "terraform.tfstate"
    }
} 

provider "azurerm" {
    features {}    
  
}