locals {
  resource_group_name = "${var.prefix}-rg"
  vnet_name            = "${var.prefix}-vnet"
  subnet_name          = "${var.prefix}-subnet"
  acr_name             = "${var.prefix}acr"
  aks_name             = "${var.prefix}-aks"
  aks_dns_prefix       = "${var.prefix}-aks"

  common_tags = merge(var.tags, {
    managed_by = "Terraform"
  })
}
