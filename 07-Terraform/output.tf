output "public_ip" {
  description = "Public IP address of the VM"
  value       = azurerm_public_ip.main.ip_address
}

output "vm_name" {
  description = "Name of the virtual machine"
  value       = azurerm_virtual_machine.main.name
}

output "resource_group" {
  description = "Resource group name"
  value       = azurerm_resource_group.example.name
}

output "storage_account" {
  description = "Storage account name"
  value       = azurerm_storage_account.example.name
}
