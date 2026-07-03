variable "prefix" {
  type        = string
  description = "Prefix for all resource names"
}

variable "location" {
  type        = string
  description = "Azure region for resources"
}

variable "vnet_address_space" {
  type        = list(string)
  description = "Address space for the virtual network"
  default     = ["10.1.0.0/16"]
}

variable "subnet_address_prefix" {
  type        = list(string)
  description = "Address prefix for the AKS subnet"
  default     = ["10.1.1.0/24"]
}

variable "acr_sku" {
  type        = string
  description = "SKU for the Azure Container Registry"
  default     = "Basic"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.acr_sku)
    error_message = "ACR SKU must be Basic, Standard or Premium"
  }
}

variable "aks_node_count" {
  type        = number
  description = "Number of nodes in the default AKS node pool"
  default     = 1
}

variable "aks_node_vm_size" {
  type        = string
  description = "VM size for AKS nodes"
  default     = "Standard_B2s"
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version for AKS"
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources"
  default = {
    environment = "staging"
    owner       = "asadul"
    project     = "aks-cicd"
  }
}
