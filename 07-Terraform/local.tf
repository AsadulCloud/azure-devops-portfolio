locals {
  # Resource names - build with prefix
  resource_group_name = "${var.prefix}-resources"
  storage_account_name = "${var.prefix}storage"
  vnet_name = "${var.prefix}-vnet"
  subnet_name = "${var.prefix}-subnet"
  nic_name = "${var.prefix}-nic"
  nsg_name = "${var.prefix}-nsg"
  public_ip_name = "${var.prefix}-pip"
  vm_name = "${var.prefix}-vm"


  # Common tags - merge user tags with auto tags
  common_tags = merge(var.tags, {
      managed_by = "Terraform"
  })
}