locals {
  naming_convention_info = {
    site         = "ml"
    env          = "en"
    app         = "zn"
    name         = "001"
  }
  tags = {
    environment = "Production"
  }

}
data "azurerm_client_config" "current" {}

module "resource_groups" {
  source = "git::https://github.com/BrettOJ/tf-az-module-resource-group?ref=main"
  resource_groups = {
    1 = {
      name                   = var.resource_group_name
      location               = var.location
      naming_convention_info = local.naming_convention_info
      tags = {
      }
    }
  }
}
module "azurerm_log_analytics_workspace" {
  source                                  = "git::https://github.com/BrettOJ/tf-az-module-azure-log-analytics-workspace?ref=main"
  location                                = var.location
  resource_group_name                     = module.resource_groups.rg_output[1].name
  allow_resource_only_permissions         = var.allow_resource_only_permissions
  local_authentication_disabled           = var.local_authentication_disabled
  sku                                     = var.sku
  retention_in_days                       = var.retention_in_days
  daily_quota_gb                          = var.daily_quota_gb
  cmk_for_query_forced                    = var.cmk_for_query_forced
  internet_ingestion_enabled              = var.internet_ingestion_enabled
  internet_query_enabled                  = var.internet_query_enabled
  reservation_capacity_in_gb_per_day      = var.reservation_capacity_in_gb_per_day
  data_collection_rule_id                 = var.data_collection_rule_id
  immediate_data_purge_on_30_days_enabled = var.immediate_data_purge_on_30_days_enabled
  tags                                    = local.tags
  naming_convention_info                  = local.naming_convention_info

  identity = {
    type         = var.identity_type
    identity_ids = var.identity_identity_ids
  }
}

module "azurerm_application_insights" {
  source                                = "git::https://github.com/BrettOJ/tf-az-module-azure-application-insights?ref=main"
  location                              = var.location
  resource_group_name                   = module.resource_groups.rg_output[1].name
  workspace_id                          = module.azurerm_log_analytics_workspace.law_output.id
  application_type                      = var.application_type
  daily_data_cap_in_gb                  = var.daily_data_cap_in_gb
  daily_data_cap_notifications_disabled = var.daily_data_cap_notifications_disabled
  retention_in_days                     = var.retention_in_days
  sampling_percentage                   = var.sampling_percentage
  disable_ip_masking                    = var.disable_ip_masking
  tags                                  = local.tags
  local_authentication_disabled         = var.local_authentication_disabled
  internet_ingestion_enabled            = var.internet_ingestion_enabled
  internet_query_enabled                = var.internet_query_enabled
  force_customer_storage_for_profiler   = var.force_customer_storage_for_profiler
  naming_convention_info                = var.naming_convention_info
}


module "azure_storage_account" {
  source              = "git::https://github.com/BrettOJ/tf-az-module-storage-account?ref=main"
  resource_group_name = module.resource_groups.rg_output.1.name
  location            = var.location
  kind                = "StorageV2"
  sku                 = "Standard_LRS"
  access_tier         = "Hot"
  assign_identity     = "SystemAssigned"
  https_traffic_only_enabled = true
  containers = {
    lvl0 = {
      name        = "lvl0"
      access_type = "private"
    }
  }
  diag_object = null
  naming_convention_info = local.naming_convention_info
  tags                   = local.tags
}


module "azurerm_key_vault" {
  source              = "git::https://github.com/BrettOJ/tf-az-module-azure-key-vault?ref=main" 
  resource_group_name = module.resource_groups.rg_output[1].name
  location            = var.location
  sku_name    = "standard"
  tenant_id           = data.azurerm_client_config.current.tenant_id
  enabled_for_deployment          = true
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true
  enable_rbac_authorization       = true
  purge_protection_enabled        = true
  public_network_access_enabled   = true
  soft_delete_retention_days      = 7 


  network_acls = {
      bypass         = "AzureServices"
      default_action = "Allow"
      ip_rules       = null
      virtual_network_subnet_ids     = null
    }
  
  naming_convention_info = local.naming_convention_info
  tags                   = local.tags
}

module "azurerm_user_assigned_identity" {
  source                 = "git::https://github.com/BrettOJ/tf-az-module-auth-user-msi?ref=main"
  resource_group_name    = module.resource_groups.rg_output[1].name
  location               = var.location
  naming_convention_info = local.naming_convention_info
  tags = local.tags
}

resource "azurerm_key_vault_access_policy" "example-identity" {
  key_vault_id = module.azurerm_key_vault.key_vault_id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = module.azurerm_user_assigned_identity.msi_output.principal_id

  // default set by service
  key_permissions = [
    "WrapKey",
    "UnwrapKey",
    "Get",
    "Recover",
  ]

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Recover",
    "Backup",
    "Restore"
  ]
}

resource "azurerm_key_vault_access_policy" "example-sp" {
  key_vault_id = module.azurerm_key_vault.key_vault_id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Get",
    "Create",
    "Recover",
    "Delete",
    "Purge",
    "GetRotationPolicy",
  ]
}

data "azuread_service_principal" "test" {
  display_name = "Azure Cosmos DB"
}

resource "azurerm_key_vault_access_policy" "example-cosmosdb" {
  key_vault_id = module.azurerm_key_vault.key_vault_id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azuread_service_principal.test.object_id

  key_permissions = [
    "Get",
    "Recover",
    "UnwrapKey",
    "WrapKey",
  ]
  depends_on = [data.azuread_service_principal.test, data.azurerm_client_config.current]
}

resource "azurerm_key_vault_key" "example" {
  name         = "boj-keyvaultkey"
  key_vault_id = module.azurerm_key_vault.key_vault_id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]
  depends_on = [module.azurerm_key_vault, azurerm_key_vault_access_policy.example-sp]
}

resource "azurerm_role_assignment" "example-role1" {
  scope                = module.azurerm_key_vault.key_vault_id
  role_definition_name = "Contributor"
  principal_id         = module.azurerm_user_assigned_identity.msi_output.principal_id
}

resource "azurerm_role_assignment" "example-role2" {
  scope                = module.azure_storage_account.sst_output.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.azurerm_user_assigned_identity.msi_output.principal_id
}

resource "azurerm_role_assignment" "example-role3" {
  scope                = module.azure_storage_account.sst_output.id
  role_definition_name = "Contributor"
  principal_id         = module.azurerm_user_assigned_identity.msi_output.principal_id
}

resource "azurerm_role_assignment" "example-role4" {
  scope                = module.azurerm_application_insights.app_insights_output.id
  role_definition_name = "Contributor"
  principal_id         = module.azurerm_user_assigned_identity.msi_output.principal_id
}

module "azurerm_machine_learning_workspace" {
  source                         = "../"
  location                       = var.location
  resource_group_name            = module.resource_groups.rg_output[1].name
  application_insights_id        = module.azurerm_application_insights.app_insights_output.id
  key_vault_id                   = module.azurerm_key_vault.key_vault_id
  storage_account_id             = module.azure_storage_account.sst_output.id
  kind                           = var.kind
  container_registry_id          = var.container_registry_id
  public_network_access_enabled  = var.public_network_access_enabled
  image_build_compute_name       = var.image_build_compute_name
  description                    = var.description
  friendly_name                  = var.friendly_name
  high_business_impact           = var.high_business_impact
  primary_user_assigned_identity = module.azurerm_user_assigned_identity.msi_output.id
  v1_legacy_mode_enabled         = var.v1_legacy_mode_enabled
  sku_name                       = var.sku_name
  tags                           = local.tags
  naming_convention_info = var.naming_convention_info

  identity = {
    type = "UserAssigned"
    identity_ids = [
      module.azurerm_user_assigned_identity.msi_output.id,
    ]
  }

  managed_network = {
    isolation_mode = var.managed_network_isolation_mode
  }

  serverless_compute = {
    subnet_id         = var.serverless_compute_subnet_id
    public_ip_enabled = var.serverless_compute_public_ip_enabled
  }

  depends_on = [
    azurerm_role_assignment.example-role1, azurerm_role_assignment.example-role2, azurerm_role_assignment.example-role3,
    azurerm_role_assignment.example-role4,
    azurerm_key_vault_access_policy.example-cosmosdb,
  ]
}


