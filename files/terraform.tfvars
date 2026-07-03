prefix   = "votingapp"
location = "Spain Central"

vnet_address_space     = ["10.1.0.0/16"]
subnet_address_prefix  = ["10.1.1.0/24"]

acr_sku            = "Basic"
aks_node_count     = 1
aks_node_vm_size   = "Standard_B2s"

tags = {
  environment = "staging"
  owner       = "asadul"
  project     = "aks-cicd"
}
