output "resource_group_name" {
  value = azurerm_resource_group.main.name
}
output "acr_login_server" {
    description = "Use this as your image registry prefix, e.g. <this>/node-web-app:latest"
  value = azurerm_container_registry.main.login_server
}
output "aks_cluster_name" {
    description = "The name of the AKS cluster"
    value = azurerm_kubernetes_cluster.main.name
}
output "aks_cluster_kube_config" {
    description = "The kube config for the AKS cluster"
    value = azurerm_kubernetes_cluster.main.kube_config_raw
    sensitive = true
}