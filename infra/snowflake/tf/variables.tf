# -- infra/snowflake/tf/variables.tf
# ============================================================================
# Variables
# ============================================================================

# ----------------------------------------------------------------------------
# Project Configuration
# ----------------------------------------------------------------------------
variable "project_code" {
  description = "Project code prefix for resource naming"
  type        = string
  default     = ""
}

variable "snowflake_config_path" {
  description = "Path to Snowflake configuration JSON file"
  type        = string
  default     = "../../../input-jsons/snowflake/config.json"
}

# ----------------------------------------------------------------------------
# Snowflake Connection
# ----------------------------------------------------------------------------
variable "snowflake_organization_name" {
  description = "Snowflake organization name"
  type        = string
  default     = ""
}

variable "snowflake_account_name" {
  description = "Snowflake account name"
  type        = string
  default     = ""
}

variable "snowflake_user" {
  description = "Snowflake user for authentication"
  type        = string
  default     = ""
}

variable "snowflake_warehouse" {
  description = "Default Snowflake warehouse"
  type        = string
  default     = ""
}

# ----------------------------------------------------------------------------
# Snowflake Roles
# ----------------------------------------------------------------------------
variable "db_provisioner_role" {
  description = "Role for database/schema provisioning"
  type        = string
  default     = ""
}

variable "warehouse_provisioner_role" {
  description = "Role for warehouse provisioning"
  type        = string
  default     = ""
}

variable "data_object_provisioner_role" {
  description = "Role for data object (tables) provisioning"
  type        = string
  default     = ""
}

variable "ingest_object_provisioner_role" {
  description = "Snowflake role for ingest object provisioning operations"
  type        = string
  default     = ""
}
# ----------------------------------------------------------------------------
# Seed Data
# ----------------------------------------------------------------------------
variable "enable_seed_data" {
  description = "Enable seeding sample data into tables"
  type        = bool
  default     = false
}
