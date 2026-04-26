terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azuread" {}

# ---------------------------------------------------------
# 1. READ Existing Infrastructure (Data Blocks)
# ---------------------------------------------------------
# These blocks fetch the details of the resources you already 
# built in your first folder so we can attach roles to them.

data "azurerm_resource_group" "existing_rg" {
  name = "bentoml-mlops-rg"
}

data "azurerm_container_registry" "existing_acr" {
  name                = "bentomlmodelregistry"
  resource_group_name = data.azurerm_resource_group.existing_rg.name
}

data "azurerm_storage_account" "existing_storage" {
  name                = "mlopsdvcstorage8392" # <-- Ensure this matches exactly!
  resource_group_name = data.azurerm_resource_group.existing_rg.name
}

# ---------------------------------------------------------
# 2. CREATE CI/CD Identity (Resource Blocks)
# ---------------------------------------------------------

data "azuread_client_config" "current" {}

resource "azuread_application" "cicd_app" {
  display_name = "mlops-cicd-pipeline-identity"
  owners       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "cicd_sp" {
  client_id                    = azuread_application.cicd_app.client_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal_password" "cicd_secret" {
  service_principal_id = azuread_service_principal.cicd_sp.object_id
}

# ---------------------------------------------------------
# 3. ASSIGN Roles to Existing Infrastructure
# ---------------------------------------------------------
# Notice how the "scope" references the "data" blocks from step 1.

resource "azurerm_role_assignment" "acr_push_role" {
  principal_id                     = azuread_service_principal.cicd_sp.object_id
  role_definition_name             = "AcrPush"
  scope                            = data.azurerm_container_registry.existing_acr.id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "storage_contributor_role" {
  principal_id                     = azuread_service_principal.cicd_sp.object_id
  role_definition_name             = "Storage Blob Data Contributor"
  scope                            = data.azurerm_storage_account.existing_storage.id
  skip_service_principal_aad_check = true
}

# ---------------------------------------------------------
# 4. Outputs
# ---------------------------------------------------------

output "cicd_azure_client_id" {
  value = azuread_application.cicd_app.client_id
}

output "cicd_azure_client_secret" {
  value     = azuread_service_principal_password.cicd_secret.value
  sensitive = true
}

output "cicd_azure_tenant_id" {
  value = data.azuread_client_config.current.tenant_id
}