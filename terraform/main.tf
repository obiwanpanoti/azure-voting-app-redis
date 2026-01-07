terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# 1. Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "student-project-rg"
  location = "East US"
}

# 2. Random String for Unique ACR Name
resource "random_string" "random" {
  length  = 6
  special = false
  upper   = false
}

# 3. Azure Container Registry (ACR)
resource "azurerm_container_registry" "acr" {
  name                = "studentacr${random_string.random.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic" # Lowest cost
  admin_enabled       = true
}

# 4. Azure Kubernetes Service (AKS)
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "student-aks-cluster"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "studentaks"

  default_node_pool {
    name       = "default"
    node_count = 1                # STRICT LIMIT: 1 Node for student quota
    vm_size    = "Standard_B2s"   # Low cost VM type
  }

  identity {
    type = "SystemAssigned"
  }
}

# 5. Allow AKS to pull images from ACR (Role Assignment)
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}

# Outputs to use later
output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "aks_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}