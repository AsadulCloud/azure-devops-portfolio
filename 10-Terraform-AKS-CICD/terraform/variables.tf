variable "project_name" {
    description = "Short name used as a prefix for all resources"
    type        = string
    default     = "asadulcicd"    
}
variable "location" {
    description = "Azure region to deploy resources"
    type        = string
    default     = "Spain Central"
}
variable "resource_group_name" {
    description = "Name of the resource group to create"
    type        = string
    default     = "asadulcicd-rg"
}
variable "vnet_address_space" {
    description = "Address space for the virtual network"
    type        = list(string)
    default     = ["10.0.0.0/16"]
}
variable "aks_subnet_address_prefix" {
    description = "Subnet CIDR for the AKS node pool"
    type        = list(string)
    default     = ["10.0.1.0/24"]
}
variable "aks_node_count" {
    description = "Number of nodes in the AKS node pool"
    type        = number
    default     = 2
}
variable "aks_node_vm_size" {
    description = "VM size for the AKS node pool"
    type        = string
    default     = "Standard_DS2_v3"
}
variable "aks_kubernetes_version" {
    description = "Kubernetes version for the AKS cluster"
    type        = string
    default     = "1.27.3"
}
variable "acr_sku" {
    description = "SKU for the Azure Container Registry"
    type        = string
    default     = "Basic"
}
