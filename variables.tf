variable "resource_group_name" {
  type        = string
  description = "value of the resource group"
}

variable "location" {
  type        = string
  description = "value of the location"
}

variable "application_insights_id" {
  type        = string
  description = "value of the application insights id"
}

variable "key_vault_id" {
  type        = string
  description = "value of the key vault id"
}

variable "storage_account_id" {
  type        = string
  description = "value of the storage account id"
}

variable "kind" {
  type        = string
  description = "value of the kind"
}

variable "container_registry_id" {
  type        = string
  description = "value of the container registry id"
}

variable "public_network_access_enabled" {
  type        = bool
  description = "value of the public network access enabled"
}

variable "image_build_compute_name" {
  type        = string
  description = "value of the image build compute name"
}

variable "description" {
  type        = string
  description = "value of the description"
}

variable "friendly_name" {
  type        = string
  description = "value of the friendly name"
}

variable "high_business_impact" {
  type        = bool
  description = "value of the high business impact"
}

variable "primary_user_assigned_identity" {
  type        = string
  description = "value of the primary user assigned identity"
}

variable "v1_legacy_mode_enabled" {
  type        = bool
  description = "value of the v1 legacy mode enabled"
}

variable "sku_name" {
  type        = string
  description = "value of the sku name"
}

variable "tags" {
  type        = map(string)
  description = "value of the tags"
}

variable "identity" {
  type = object({
    type         = string
    identity_ids = list(string)
  })
  description = "value of the identity"
}

variable "encryption" {
  type = object({
    key_vault_id              = string
    key_id                    = string
    user_assigned_identity_id = string
  })
  description = "value of the encryption"
  default = null
}

variable "managed_network" {
  type = object({
    isolation_mode = string
  })
  description = "value of the managed network"
 default = null
}

variable "serverless_compute" {
  type = object({
    subnet_id         = string
    public_ip_enabled = bool
  })
  description = "value of the serverless compute"
  default = null
}

variable "feature_store" {
  type = object({
    computer_spark_runtime_version = string
    offline_connection_name        = string
    online_connection_name         = string
  })
  description = "value of the feature store"
  default = null
  
}

variable "naming_convention_info" {
  type = object({
    project_code = string
    env          = string
    zone         = string
    tier         = string
    name         = string
    agency_code  = string
  })
  description = "value of the naming convention info"
  
}
