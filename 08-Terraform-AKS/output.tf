output "resource_group_name" {
  value = azurerm_resource_group.main.name
  description = "The name of the resource group"    
}
output "acr_login_server" {
  value = azurerm_container_registry.main.login_server
  description = "The login server of the Azure Container Registry"
}
output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.main.name
  description = "The name of the AKS cluster"
}
output "acr_name" {
  value = azurerm_container_registry.main.name
  description = "The name of the Azure Container Registry"
}
output "aks_kube_config" {
  value = azurerm_kubernetes_cluster.main.kube_config_raw
  description = "The raw kube config of the AKS cluster"
  sensitive = true
}
output "aks_node_resource_group" {
  value = azurerm_kubernetes_cluster.main.node_resource_group
  description = "The resource group of the AKS cluster nodes"
}
output "public_ip_address" {
  value = azurerm_public_ip.main.ip_address
  description = "The public IP address of the AKS cluster"
}