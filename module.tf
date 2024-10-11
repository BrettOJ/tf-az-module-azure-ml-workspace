resource "azurerm_machine_learning_workspace" "azure_ml_ws" {
  name                           = module.azml_ws_name.naming_convention_output[var.naming_convention_info.name].names.0
  location                       = var.location
  resource_group_name            = var.resource_group_name
  application_insights_id        = var.application_insights_id
  key_vault_id                   = var.key_vault_id
  storage_account_id             = var.storage_account_id
  kind                           = var.kind
  container_registry_id          = var.container_registry_id
  public_network_access_enabled  = var.public_network_access_enabled
  image_build_compute_name       = var.image_build_compute_name
  description                    = var.description
  friendly_name                  = var.friendly_name
  high_business_impact           = var.high_business_impact
  primary_user_assigned_identity = var.primary_user_assigned_identity
  v1_legacy_mode_enabled         = var.v1_legacy_mode_enabled
  sku_name                       = var.sku_name
  tags                           = var.tags

  identity {
    type         = var.identity.type
    identity_ids = var.identity.identity_ids

  }

  dynamic encryption {
    for_each = var.encryption != null ? [1] : []
    content {
      user_assigned_identity_id = var.encryption.user_assigned_identity_id
      key_vault_id              = var.encryption.key_vault_id
      key_id                    = var.encryption.key_id
    }
  }

  dynamic managed_network {
    for_each = var.managed_network != null ? [1] : []
    content {
        isolation_mode = var.managed_network.isolation_mode
    }
  }

  dynamic serverless_compute {
    for_each = var.serverless_compute != null ? [1] : []
    content {
    subnet_id         = var.serverless_compute.subnet_id
    public_ip_enabled = var.serverless_compute.public_ip_enabled
    }
  }
  
  dynamic feature_store {
    for_each = var.feature_store != null ? [1] : []
    content {
      computer_spark_runtime_version = var.feature_store.computer_spark_runtime_version
      offline_connection_name        = var.feature_store.offline_connection_name
      online_connection_name         = var.feature_store.online_connection_name
    }
}
}


