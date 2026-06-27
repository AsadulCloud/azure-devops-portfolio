#!/bin/bash



# Backup script for Terraforms state files and configuration files.

RESOURCE_GROUP_NAME="tfstate-backup-rg"
STORAGE_ACCOUNT_NAME="newsta$RANDOM"
CONTAINER_NAME="tfstate"


# Create a resource group
az group create --name $RESOURCE_GROUP_NAME --location eastus

# Create a storage account
az storage account create --name $STORAGE_ACCOUNT_NAME --resource-group $RESOURCE_GROUP_NAME --location eastus --sku Standard_LRS

# Create a blob container
az storage container create --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME

# Add this at the end of your script
echo "Add this to your backend block:"
echo "storage_account_name = \"$STORAGE_ACCOUNT_NAME\""
echo "container_name = \"$CONTAINER_NAME\""
echo "key = \"dev.terraform.tfstate\""