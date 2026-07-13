# Copy this file to terraform.tfvars and adjust values before running terraform apply
# terraform.tfvars should NEVER be committed if it contains secrets (it doesn't here, but good habit)
project_name = "asadulcicd"
resource_group_name = "asadulcicd-rg"
location = "spaincentral"
aks_node_count = 1
aks_node_vm_size = "Standard_B2s"
aks_kubernetes_version = "1.36.0"
vnet_address_space = ["10.0.0.0/16"]
