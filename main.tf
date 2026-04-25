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
resource "azurerm_resource_group" "dvc_rg" {
  name     = "rg-mlops-dvc"
  location = "East US" # Update to your preferred region
}

# 2. Create the Storage Account
resource "azurerm_storage_account" "dvc_storage" {
  name                     = "dvcmloblobstorage" # Must be globally unique, lowercase, and numbers only
  resource_group_name      = azurerm_resource_group.dvc_rg.name
  location                 = azurerm_resource_group.dvc_rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS" 
}

# 3. Create the Blob Container
resource "azurerm_storage_container" "dvc_container" {
  name                  = "dvc"
  storage_account_name  = azurerm_storage_account.dvc_storage.name
  container_access_type = "private"
}

# 4. Generate a 1-year SAS Token with all necessary permissions for DVC
data "azurerm_storage_account_sas" "dvc_sas" {
  connection_string = azurerm_storage_account.dvc_storage.primary_connection_string
  https_only        = true

  resource_types {
    service   = true
    container = true
    object    = true
  }

  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }

  start  = timestamp()
  expiry = timeadd(timestamp(), "8760h") # 1 year (365 days * 24 hours)

  permissions {
    read    = true
    write   = true
    delete  = true
    list    = true
    add     = true
    create  = true
    update  = true
    process = false
    tag     = false
    filter  = false
  }
}

# 5. Output the values needed for DVC configuration
output "dvc_storage_account_name" {
  value       = azurerm_storage_account.dvc_storage.name
  description = "The name of the Azure Storage Account."
}

output "dvc_container_name" {
  value       = azurerm_storage_container.dvc_container.name
  description = "The name of the Blob Container."
}

output "dvc_connection_string" {
  value       = azurerm_storage_account.dvc_storage.primary_connection_string
  sensitive   = true
  description = "The primary connection string. Can be used as an alternative to the SAS token."
}

output "dvc_sas_token" {
  value       = data.azurerm_storage_account_sas.dvc_sas.sas
  sensitive   = true
  description = "The generated SAS token for DVC local configuration."
}