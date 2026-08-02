# variables.tf
# Central place for values you might want to change without touching main.tf
variable "resource_group_name" {
  description = "The name of the resource group"
  default     = "capstone-rg"
}
variable "location" {
  description = "The Azure region to deploy resources"
  default     = "polandcentral"
}
variable "vm_size" {
  description = "The size of the virtual machine"
  default     = "Standard_B2s_v2"
}
variable "admin_username" {
  description = "The admin username for the virtual machine"
  default     = "azureuser"
}