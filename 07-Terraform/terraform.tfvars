prefix = "demo"
location = "Spain Central"
admin_username = "azureuser"
admin_password = "Asad123456789@"
vm_size = "Standard_B2ats_v2"
vnet_address_space = ["10.0.0.0/8"]
subnet_address_space = ["10.0.1.0/24"]
allowed_ports = [22, 80, 443]
public_ip_allocation_method = "Static"
os_disk_caching = "ReadWrite"
os_disk_storage_account_type = "Standard_LRS"
tags = {
  environment = "staging"
  owner     = "asadul"
}