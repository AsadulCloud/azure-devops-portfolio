prefix = "votingapp"
location = "Spain Central"
vnet_address_space = ["10.0.0.0/16"]
subnet_address_space = ["10.0.1.0/24"]
admin_username = "azureuser"
admin_password = "Asad123456789@"
aks_subnet_address_space = [ "10.0.2.0/24" ]

acr_sku = "Basic"
aks_node_count = 1
aks_node_vm_size = "Standard_B2s_v2"


tags = {
  Environment = "Staging"
  Owner       = "Asad"
  Project     = "AKS-CICD"
}