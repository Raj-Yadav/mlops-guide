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

# 1. Create a Resource Group
resource "azurerm_resource_group" "mlops_rg" {
  name     = "bentoml-mlops-rg"
  location = "East US" # Feel free to change to your preferred region
}

# 2. Create the Azure Container Registry (ACR)
resource "azurerm_container_registry" "acr" {
  name                = "bentomlmodelregistry" # IMPORTANT: This name must be globally unique across Azure
  resource_group_name = azurerm_resource_group.mlops_rg.name
  location            = azurerm_resource_group.mlops_rg.location
  sku                 = "Basic"
  
  # Enabling admin gives us a username and password to use with `docker login`
  admin_enabled       = true 
}

# 3. Create the storage account
resource "azurerm_storage_account" "dvc_storage" {
  # IMPORTANT: Change the numbers below to something random so the name is globally unique
  name                     = "mlopsdvcstorage8392" 
  resource_group_name      = azurerm_resource_group.mlops_rg.name
  location                 = azurerm_resource_group.mlops_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# 4. Output the credentials needed for Docker
output "registry_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "registry_username" {
  value = azurerm_container_registry.acr.admin_username
}

output "registry_password" {
  value     = azurerm_container_registry.acr.admin_password
  sensitive = true
}