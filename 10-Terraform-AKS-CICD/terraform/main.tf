# --------------------------------------------------------------------------------------------
# Resource Group - the container that holds every resource for your project
# --------------------------------------------------------------------------------------------
resource "azurerm_resource_group" "main" {
    name     = var.resource_group_name
    location = var.location
}

# --------------------------------------------------------------------------------------------
# Network - Virtual Network and Subnet for AKS
# --------------------------------------------------------------------------------------------
resource "azurerm_virtual_network" "main" {
    name                = "${var.project_name}-vnet"
    address_space       = var.vnet_address_space
    location            = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name
}
resource "azurerm_subnet" "aks" {
    name                 = "${var.project_name}-aks-subnet"
    resource_group_name  = azurerm_resource_group.main.name
    virtual_network_name = azurerm_virtual_network.main.name
    address_prefixes     = var.aks_subnet_address_prefix
} 
# --------------------------------------------------------------------------------------------
# Azure Container Registry (ACR) - stores your Docker images
# --------------------------------------------------------------------------------------------
resource "azurerm_container_registry" "main" {
    name                     = "${var.project_name}acr"
    resource_group_name      = azurerm_resource_group.main.name
    location                 = azurerm_resource_group.main.location
    sku                      = var.acr_sku
    admin_enabled            = false
}
# --------------------------------------------------------------------------------------------
# Azure Kubernetes Service (AKS) - the managed Kubernetes cluster
# --------------------------------------------------------------------------------------------
resource "azurerm_kubernetes_cluster" "main" {
    name                = "${var.project_name}-aks"
    location            = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name
    dns_prefix          = "${var.project_name}-aks"
    kubernetes_version = var.aks_kubernetes_version

oidc_issuer_enabled = true
    default_node_pool {
        name                = "default"
        node_count          = var.aks_node_count
        vm_size             = var.aks_node_vm_size
        vnet_subnet_id      = azurerm_subnet.aks.id
    }
    # System assigned managed identity for the AKS cluster - AKS uses this to talk to other
    # Azure resources like ACR, without needing storing credentials.
    identity {
        type = "SystemAssigned"
    }
    network_profile {
        network_plugin    = "azure"
        load_balancer_sku = "standard"
        service_cidr      = "10.2.0.0/16"
        dns_service_ip    = "10.2.0.10"
    }
}
# --------------------------------------------------------------------------------------------
# RBAC - Role Assignment for AKS to pull images from ACR
# This is the Terraform-native replacement for `az aks update --attach-acr`
# --------------------------------------------------------------------------------------------
resource "azurerm_role_assignment" "aks_acr_pull" {
    scope                = azurerm_container_registry.main.id
    role_definition_name = "AcrPull"
    principal_id         = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
    skip_service_principal_aad_check = true
}   