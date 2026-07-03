locals {
  resource_group_name = "${var.prefix}-rg"
  vnet_name = "${var.prefix}-vnet"
  subnet_name = "${var.prefix}-subnet"
  acr_name = "${var.prefix}acr0001"
  aks_name = "${var.prefix}-aks"
  aks_dns_prefix = "${var.prefix}-aks"
  aks_subnet_name = "${var.prefix}-aks-subnet"
  agent_subnet_name = "${var.prefix}-agent-subnet"
  common_tags = merge(
    var.tags,
    {
      "Prefix" = var.prefix
    }
  )     

}