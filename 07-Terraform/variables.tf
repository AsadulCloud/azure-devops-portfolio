variable "prefix" {
  type        = string
  description = "Prefix for resource names"
}
variable "location" {
  type        = string
  description = "Azure region for resources"
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
variable "vm_size" {
  type        = string
  description = "Size of the virtual machine"
  default     = "Standard_B1s"
  }
variable "vnet_address_space" {
  type        = list(string)
  description = "Address space for the virtual network"
  default     = ["10.0.0.0/8"]
}
variable "subnet_address_space" {
  type        = list(string)
  description = "Address space for the subnet"
  default     = ["10.0.1.0/24"] 
}
variable "storage_account_tier" {
  type        = string
  description = "Tier for the storage account"
  default     = "Standard"
}
variable "storage_account_replication_type" {
  type        = string
  description = "Replication type for the storage account"
  default     = "LRS"
}
variable "allowed_ports" {
  type        = list(number)
  description = "List of allowed ports for the network security group"
  default     = [22, 80, 443]
}
variable "public_ip_allocation_method" {
  type        = string
  description = "Allocation method for the public IP"
  default     = "Static"
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
  description = "Tags for all resources"
  default     = {
    environment = "staging"
    owner     = "asadul"
  }
}