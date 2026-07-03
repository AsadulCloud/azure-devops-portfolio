variable "prefix" {
  type        = string
  description = "Prefix for resource names"
}
variable "location" {
  type        = string
  description = "Azure region for resources"
}
variable "vnet_address_space" {
  type        = list(string)
  description = "Address space for the virtual network"
  default     = ["10.0.0.0/16"]
}
variable "subnet_address_space" {
  type        = list(string)
  description = "Address space for the subnet"
  default     = ["10.0.1.0/24"]
}
variable "aks_subnet_address_space" {
  type        = list(string)
  description = "Address space for the AKS subnet"
  default     = ["10.0.2.0/24"]
}   
variable "acr_sku" {
  type        = string
  description = "SKU for the Azure Container Registry"
    default     = "Basic"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.acr_sku)
    error_message = "The ACR SKU must be one of: Basic, Standard, Premium."
  }
}
variable "aks_node_count" {
  type        = number
  description = "Number of nodes in the AKS cluster"
  default     = 3
}
variable "aks_node_vm_size" {
  type        = string
  description = "VM size for the AKS nodes"
  default     = "Standard_B2s_v2"
}
variable "aks_kubernetes_version" {
  type        = string
  description = "Kubernetes version for the AKS cluster"
  default     = null # Use the default version if not specified
}
variable "vm_size" {
  type        = string
  description = "Size of the virtual machine"
  default     = "Standard_B2ats_v2"
}
variable "admin_username" {
  type        = string
  description = "VM admin username"
}
variable "admin_password" {
  type        = string
  description = "VM admin password"
  sensitive   = true
}
variable "os_disk_caching" {
  type        = string
  description = "Caching type for the OS disk"
  default     = "ReadWrite"
}
variable "os_disk_storage_account_type" {
  type        = string
  description = "Storage account type for the OS disk"
  default     = "Standard_LRS"
}  
variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {
    Environment = "Staging"
    Owner     = "Asad"
    Project     = "AKS-CICD"
  }
}
